#!/bin/bash

## snakemake runner
## Using slurm profile
## @sbamin

## get dir where run_snakemake.sh is present
## https://stackoverflow.com/a/246128/1243763
## SMKDIR is being referenced in cluster profile under ~/.config/snakemake/
SMKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "${SMKDIR}" && \
export SMKDIR

printf "Workflow SMKDIR: %s" "${SMKDIR}"

## snakemake config dir for jobscript, pre and post-job scripts
## These are optional config and not being used at present
SMK_CONF_DIR="${HOME}/.smk_confs"

if [[ ! -d "${SMK_CONF_DIR}" ]]; then
	echo -e "WARN: snakemake optional config directory is missing at ${SMK_CONF_DIR}\n" >&2
fi

## number of hpc jobs to submit at a time
NJOBS="${NJOBS:-100}"
echo "Number of jobs to submit to hpc: ${NJOBS}"

## make directory where HPC logs will be saved else qsub will return an error
## WORKDIR is being referenced in cluster profile under ~/.config/snakemake/
WORKDIR="/fastscratch/${USER}/snakemake/toymake"
export WORKDIR
mkdir -p "${WORKDIR}"/logs/sumner

TSTAMP=$(date +%d%b%y_%H%M%S%Z)

## Plot rulegraph
snakemake --rulegraph -s Snakefile | dot -Tpng >| "${WORKDIR}"/logs/toymake_flow_"$TSTAMP".png

snakemake --dag -s Snakefile | dot -Tpdf >| "${WORKDIR}"/logs/toymake_flow_"$TSTAMP".pdf

printf "LOOGER\t%s\ttoymake\tSTART\n" "$TSTAMP"

## Local run
## snakemake -s Snakefile --jobs "${NJOBS}"

## HPC run using sumner slurm profile
snakemake --profile sumner -s Snakefile --verbose --stats "${WORKDIR}"/logs/toymake_stats.json |& tee -a "${WORKDIR}"/logs/run_toymake_"$TSTAMP".log && \
EXITSTAT=$? && \
printf "LOOGER\t%s\ttoymake\tEND\t%s\nPS: Check snakemake logs for a valid exit status.\n" "$TSTAMP" "$EXITSTAT"

## END ##
