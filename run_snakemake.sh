#!/bin/bash

snakemake --jobs 100 --jobscript ~/pipelines/snakemake/toymake/jobscript.sh --latency-wait 10 --max-jobs-per-second 2 --cluster-config "confs/torque_helix.json" --jobname "{jobid}.{cluster.name}" --drmaa " -S /bin/bash -j {cluster.j} -M {cluster.M} -m {cluster.m} -q {cluster.queue} -l nodes={cluster.nodes}:ppn={cluster.ppn},walltime={cluster.walltime} -l mem={cluster.mem}m -e {cluster.stderr} -o {cluster.stdout}" --rerun-incomplete
