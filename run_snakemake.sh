#!/bin/bash

tstamp=$(date +%d%b%y_%H%M%S_%Z)
echo -e "\n${tstamp}: start snakemake\n"

## make directory where HPC logs will be saved else qsub will return an error
mkdir -p /fastscratch/amins/snakemake/toymake/logs/helix/

snakemake --jobs 100 --jobscript ~/pipelines/snakemake/toymake/jobscript.sh --latency-wait 120 --max-jobs-per-second 2 --cluster-config "confs/torque_helix.json" --jobname "{jobid}.{cluster.name}" --drmaa " -S /bin/bash -j {cluster.j} -M {cluster.M} -m {cluster.m} -q {cluster.queue} -l nodes={cluster.nodes}:ppn={cluster.ppn},walltime={cluster.walltime} -l mem={cluster.mem}m -e {cluster.stderr} -o {cluster.stdout}" --rerun-incomplete -r -p --stats toymake_stats.json

echo -e "\n${tstamp}: end snakemake with exit: $?\n"

## END ##
