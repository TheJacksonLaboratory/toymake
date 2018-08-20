## snakemake toy example

Compliant with [VerhaakEnv](https://github.com/TheJacksonLaboratory/VerhaakEnv)

#### To run

*   `ssh helix` and clone this repository 

```sh
mkdir -p ~/pipelines/snakemake
cd ~/pipelines/snakemake

git clone git@github.com:TheJacksonLaboratory/toymake.git
cd toymake
```

*   Edit `config.yaml` to match your username and valid path for `smk_home` and `workdir`.

*   Edit `Snakefile` to match your username (replace `amins`).

*   Make log output directory under `workdir` path, e.g.,

```sh
mkdir -p /fastscratch/"${USER}"/snakemake/toymake/logs/helix
```

*   Activate `rvenv2018`

```sh
source activate rvenv2018

## OR less preferable,

module load rvenv/2.0
```

*   Plot workflow

```sh
snakemake --dag | dot -Tpdf >| dag.pdf
snakemake --rulegraph | dot -Tpdf >| dag_rules.pdf
```

*   Run dummy workflow (will take ~1 minute to finish)

```sh
## dry run
snakemake -nrp

## actual run: submit to HPC Helix
./run_snakemake.sh |& tee -a run.log
```

end

