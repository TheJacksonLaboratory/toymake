#!/bin/bash

## get dir where run_snakemake.sh is present
## https://stackoverflow.com/a/246128/1243763
SMKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "${SMKDIR}" && \
export SMKDIR

printf "Workflow SMKDIR: %s" "${SMKDIR}"

## snakemake config dir for jobscript, pre and post-job scripts
SMK_CONF_DIR="${HOME}/.smk_confs"

if [[ ! -d "${SMK_CONF_DIR}" ]]; then
	echo -e "ERROR: snakemake config directory is missing at ${SMK_CONF_DIR}\n" >&2
	exit 1
fi

## number of hpc jobs to submit at a time
NJOBS="${NJOBS:-100}"
echo "Number of jobs to submit to hpc: ${NJOBS}"

## make directory where HPC logs will be saved else qsub will return an error
WORKDIR="/fastscratch/amins/snakemake/toymake"
mkdir -p "${WORKDIR}"/logs/sumner

TSTAMP=$(date +%d%b%y_%H%M%S%Z)

snakemake --rulegraph -s Snakefile | dot -Tpng >| "${WORKDIR}"/logs/toymake_flow_"$TSTAMP".png

snakemake --dag -s Snakefile | dot -Tpdf >| "${WORKDIR}"/logs/toymake_flow_"$TSTAMP".pdf

printf "LOOGER\t%s\ttoymake\tSTART\n" "$TSTAMP"

## Local run
## snakemake -s Snakefile --jobs "${NJOBS}"

## HPC run using sumner slurm profile
snakemake --profile sumner -s Snakefile --jobs "${NJOBS}" --verbose

# snakemake -s Snakefile --jobs "${NJOBS}" --jobscript "${SMK_CONF_DIR}"/jobscript.sh --latency-wait 120 --max-jobs-per-second 1 --cluster-config "${SMKDIR}/confs/torque_helix.json" --jobname "{jobid}.{cluster.name}" --drmaa " -S /bin/bash -j {cluster.j} -M {cluster.M} -m {cluster.m} -q {cluster.queue} -l nodes={cluster.nodes}:ppn={cluster.ppn},walltime={cluster.walltime} -l mem={cluster.mem}m -e {cluster.stderr} -o {cluster.stdout}" --rerun-incomplete -r -p --stats toymake_stats.json |& tee -a run_toymake_"$TSTAMP".log && \
# EXITSTAT=$? && \
# printf "LOOGER\t%s\ttoymake\tEND\t%s\n" "$TSTAMP" "$EXITSTAT"

## END ##
