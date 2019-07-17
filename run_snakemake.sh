#!/bin/bash

## get dir where run_snakemake.sh is present
## https://stackoverflow.com/a/246128/1243763
SMKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${SMKDIR}" && \
echo "Workdir is $(pwd)"

## number of hpc jobs to submit at a time
NJOBS="${NJOBS:-100}"
echo "Number of jobs to submit to hpc: ${NJOBS}"

## make directory where HPC logs will be saved else qsub will return an error
mkdir -p /fastscratch/amins/snakemake/toymake/logs/helix/

TSTAMP=$(date +%d%b%y_%H%M%S%Z)

snakemake --rulegraph -s Snakefile | dot -Tpng >| toymake_flow_"$TSTAMP".png && \
snakemake --dag -s Snakefile | dot -Tpdf >| toymake_dag_"$TSTAMP".pdf && \
printf "LOOGER\t%s\ttoymake\tSTART\n" "$TSTAMP" && \
snakemake -s Snakefile --jobs "${NJOBS}" --jobscript "${SMKDIR}"/jobscript.sh --latency-wait 120 --max-jobs-per-second 1 --cluster-config "${SMKDIR}/confs/torque_helix.json" --jobname "{jobid}.{cluster.name}" --drmaa " -S /bin/bash -j {cluster.j} -M {cluster.M} -m {cluster.m} -q {cluster.queue} -l nodes={cluster.nodes}:ppn={cluster.ppn},walltime={cluster.walltime} -l mem={cluster.mem}m -e {cluster.stderr} -o {cluster.stdout}" --rerun-incomplete -r -p --stats toymake_stats.json |& tee -a run_toymake_"$TSTAMP".log && \
EXITSTAT=$? && \
printf "LOOGER\t%s\ttoymake\tEND\t%s\n" "$TSTAMP" "$EXITSTAT"

## END ##
