## snakemake toy example

## @sbamin

from snakemake.utils import min_version

min_version("5.14")

import json
import yaml
import subprocess
import warnings
import sys
import os.path

from os import access, R_OK, environ
from snakemake.utils import validate

#################################### config ####################################
## always run snakemake from snakemake home dir and not a workdir
## PS: getcwd will get the actual path and not a symlink, if any.
## Prefer absolute path as symlinked dirs may return errors
smk_home = os.getenv("PWD")

##### Load user config #####
config = yaml.load(open(os.path.join(smk_home, "config.yaml")), Loader=yaml.FullLoader)

## quit if snakemake home dir differs between current work dir and config.yaml
if smk_home != config["smk_home"]:
    sys.exit(
        "snakemake homedir, smk_home in config.yaml: {} is different than current "
        "workdir: {}".format(config["smk_home"], smk_home)
    )


## set workdir outside of snakemake home
workdir: config["workdir"]


##### HPC scheduler resources #####
## Override by --profile config
## HPC_CONF = yaml.load(open(os.path.join(smk_home, config["cluster_specs"])))

##### Parse SysInfo #####
smk_username = environ["USER"]
smk_workdir = config["workdir"]

#### IMPORTANT: bash config: enabled in jobscript.sh ####
shell.executable("/bin/bash")

## If running snakemake on a local node, uncomment shell.prefix
## to source user bashrc and profile.d setup
## With default snakemake strict mode, it may  still throw
## an error with unbound variables while loading bashrc
# shell.prefix("PS1=\"$-\" ; export PS1")

## If running snakemake on HPC using cluster configs,
## avoid setting shell.prefix at all.
## Instead prefer using jobscript.sh

######################### RULE SPECIFIC CONFIGS #########################
## keep forward slash at the end for relative dirs
SAMPLE_BASEDIR = "/home/amins/pipelines/snakemake/toymake/data/"
OUTDIR = "results/final/"


wildcard_constraints:
    case_barcode="caseA|caseB",


SAMPLES = ["caseA", "caseB"]


################################# RULES #################################
## the last rule to be executed
## For most parts, prefer running individual modules
rule all:
    input:
        expand("results/final/{case_barcode}/merged.final.txt", case_barcode=SAMPLES),


rule step1:
    input:
        file1="/home/amins/pipelines/snakemake/toymake/data/samples/{case_barcode}/file1.tsv",
        file2="/home/amins/pipelines/snakemake/toymake/data/samples/{case_barcode}/file2.tsv",
    output:
        merged=protected("results/final/{case_barcode}/merged.tsv"),
    resources:
        mem_mb=4098,
    log:
        "logs/sumner/step1/{case_barcode}.log",
    benchmark:
        "benchmarks/step1/{case_barcode}.txt"
    message:
        "Run step1\n"
        "Case ID: {wildcards.case_barcode}\n"
    shell:
        """
        which java
        which gunzip
        echo $PATH
        # RUNNING_JOBS comes from prerun.sh via jobscript.sh
        # echo "RUNNING JOBS CAP: $RUNNING_JOBS"

        ## switch conda env
        ## check bash set flags
        echo "$-"
        source /home/amins/anaconda3/etc/profile.d/conda.sh && conda activate r-reticulate
        echo "$-"

        which R
        samtools --version
        echo $PATH

        cat {input.file1} {input.file2} >> {output.merged}
        echo "ran step1 for {input.file1} and {input.file2}" >> {output.merged} ;
        """


rule step2:
    input:
        merged="results/final/{case_barcode}/merged.tsv",
    output:
        merged_tarball="results/final/{case_barcode}/merged.step2.tsv.tar.gz",
    threads: 4
    log:
        "logs/sumner/step2/{case_barcode}.log",
    benchmark:
        "benchmarks/step2/{case_barcode}.txt"
    message:
        "Run step2\n"
        "Case ID: {wildcards.case_barcode}\n"
    shell:
        """
        ## switch conda env
        echo "$-"
        source /home/amins/anaconda3/etc/profile.d/conda.sh && conda activate r-reticulate
        echo "$-"

        which R
        samtools --version
        echo $PATH

        ## switch conda env again
        conda activate dev
        echo "$-"
        which R
        samtools --version

        ## revert to previous: r-reticulate
        conda deactivate
        echo "$-"
        which R
        samtools --version

        ## revert to original: snakemake
        conda deactivate
        echo "$-"
        which python

        echo "run step2 for {input.merged}"
        tar cvzf {output.merged_tarball} {input.merged} ;
        """


rule step3:
    input:
        "results/final/{case_barcode}/merged.step2.tsv.tar.gz",
    output:
        "results/final/{case_barcode}/merged.final.txt",
    log:
        "logs/sumner/step3/{case_barcode}.log",
    benchmark:
        "benchmarks/step3/{case_barcode}.txt"
    message:
        "Run step3\n"
        "Case ID: {wildcards.case_barcode}\n"
    shell:
        """
        module load  s7gatk
        command -v gatk
        gatk --version

        echo $PATH
        echo $LD_LIBRARY_PATH
        echo 'data dir is $(pwd)'

        tar xvzf {input}

        echo -e "####\nran step3 for {input}\n####\n" >> {output}
        find results/final/{wildcards.case_barcode} -type f -name "*.tsv" | parallel cat {{}} >> {output} ;
        """


## END ##
