## snakemake toy example

Compliant with JAX HPC Sumner (Cent OS7) using slurm v18.08.8 and minimum Snakemake version 5.14.

Note: Following workflow may need to be tweaked for the newer versions of Snakemake 7.0 or higher. Alternately, you may like a simpler version of snakemake profile from https://github.com/jdblischak/smk-simple-slurm instead of using one given in the [profile/sumner/config.yaml](profile/sumner/config.yaml) directory.

#### To run

*   `ssh sumner` and clone this repository

```sh
mkdir -p ~/pipelines/snakemake
cd ~/pipelines/snakemake

git clone git@github.com:TheJacksonLaboratory/toymake.git
cd toymake
```

*   Edit `config.yaml` to match your username and valid path for `smk_home` and `workdir`.

*   Edit `Snakefile` to match your username (replace `amins`).

*   Setup slurm profile. [Read details here first](https://github.com/Snakemake-Profiles/slurm)

```sh
mkdir -p ~/.config/snakemake/sumner/
rsync -avhP ~/pipelines/snakemake/toymake/profile/sumner/ ~/.config/snakemake/sumner/
```

* Run workflow

```sh
./run_snakemake.sh |& tee -a run.log
```

* Expected output

![Expected output](output.png "Expected output")


_end_
