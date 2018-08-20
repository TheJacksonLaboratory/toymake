## snakemake toy example

from snakemake.utils import min_version
min_version("5.2")

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
smk_home = os.getcwd()

##### Load user config #####
config = yaml.load(open(os.path.join(smk_home, "config.yaml")))

## quit if snakemake home dir differs between current work dir and config.yaml
if(smk_home != config['smk_home']):
    sys.exit("snakemake workdir in config.yaml: {} is different than current "
        "workdir: {}".format(config['smk_home'], smk_home))

##### HPC scheduler resources #####
PBS_CONF = json.load(open(config["cluster_specs"]))

## set workdir outside of snakemake home
workdir: config["workdir"]

##### Parse SysInfo #####
smk_username = environ['USER']
smk_workdir = config['workdir']

## include common rules
include: "rules/common.smk"

#### bash config: enabled in jobscript.sh ####
shell.executable("/bin/bash")
## enable debugging; read jobscript.sh for additional bash configs
shell.prefix('set +x ;')

## keep forward slash at the end for relative dirs
SAMPLE_BASEDIR="/home/amins/pipelines/snakemake/toymake/data/"
OUTDIR="results/final/"

wildcard_constraints:
    case_barcode="caseA|caseB"

SAMPLES = ["caseA", "caseB"]

################################# TARGET RULES #################################
## the last rule to be executed
## For most parts, prefer running individual modules
rule all:
    input:
        expand("results/final/{case_barcode}/merged.final.txt", case_barcode = SAMPLES)

rule step1:
    input:
        file1 = "/home/amins/pipelines/snakemake/toymake/data/samples/{case_barcode}/file1.tsv",
        file2 = "/home/amins/pipelines/snakemake/toymake/data/samples/{case_barcode}/file2.tsv"
    output:
        merged = protected("results/final/{case_barcode}/merged.tsv")
    params:
        mem = PBS_CONF["step1"]["mem"]
    threads:
        PBS_CONF["step1"]["ppn"]
    log:
        "logs/helix/step1/{case_barcode}.log"
    benchmark:
        "benchmarks/step1/{case_barcode}.txt"
    message:
        "Run step1\n"
        "Case ID: {wildcards.case_barcode}\n"
    shell:"""
        which java
        which gunzip
        echo $PATH
        echo $PS1

        cat {input.file1} {input.file2} >> {output.merged}
        echo "ran step1 for {input.file1} and {input.file2}" >> {output.merged} ;
        """

rule step2:
    input:
        merged=protected("results/final/{case_barcode}/merged.tsv")
    output:
        merged_tarball="results/final/{case_barcode}/merged.step2.tsv.tar.gz"
    params:
        mem = PBS_CONF["step2"]["mem"]
    threads:
        PBS_CONF["step2"]["ppn"]
    log:
        "logs/helix/step2/{case_barcode}.log"
    benchmark:
        "benchmarks/step2/{case_barcode}.txt"
    message:
        "Run step2\n"
        "Case ID: {wildcards.case_barcode}\n"
    shell:"""
        module load rvgatk4
        which gatk
        module load rvhtsenv/1.8
        which samtools
        echo $PATH

        echo "run step2 for {input.merged}"
        tar cvzf {output.merged_tarball} {input.merged} ;
        """

rule step3:
    input: "results/final/{case_barcode}/merged.step2.tsv.tar.gz"
    output: "results/final/{case_barcode}/merged.final.txt"
    log:
        "logs/helix/step3/{case_barcode}.log"
    benchmark:
        "benchmarks/step3/{case_barcode}.txt"
    message:
        "Run step3\n"
        "Case ID: {wildcards.case_barcode}\n"
    shell:"""
        module load rvgatk4
        which gatk
        echo $PATH
        echo $LD_LIBRARY_PATH
        echo 'data dir is $(pwd)'

        tar xvzf {input}

        echo -e "####\nran step3 for {input}\n####\n" >> {output}
        find results/final/{wildcards.case_barcode} -type f -name "*.tsv" | parallel cat {{}} >> {output} ;
        """

## END ##
