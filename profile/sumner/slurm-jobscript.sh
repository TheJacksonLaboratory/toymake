#!/bin/bash

## @sbamin
## Sumner HPC at JAX

## Following row is required by a snakemake slurm profile and
## needs to be kept as commented with a single #
# properties = {properties}

## enable strict error check
## allow empty variables until user bashrc has been loaded
## for PS1, PROMPT_COMMAND, etc.
## Read http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eo pipefail

## enable bash debug
## set -x

# following will always overwrite previous output file, if any.
set +o noclobber

########## workaround to source bashrc and user env ##########
## If snankemake is running in non-interactive bash mode,
## allow an exception to load bashrc (and profile.d) settings
## No need to custom load user .bashrc and .profile.d
## These settings are now managed at user bash start up level by making
## sure that PS1 variable is never unset and bash run as login shell.

#### defunct ####
    ## must wait for bashrc to load before snankemake can run
    ## then set full bash strict mode
    ## exec_job is a python variable: marked by a single set of curly braces
    # . "${{HOME}}"/.bashrc && \
    # sleep 2 && \
    # set -euo pipefail
#### end defunct ####

STARTSMAKE=$(date +%d%b%y_%H%M%S_%Z)
printf '\nLOGGER\t%s\tSNAKEMAKE END\n' "${{STARTSMAKE}}"

## snakemake requires additional set of curly braces for bash env variables
if [[ -f "${{HOME}}"/.bashrc && -x "${{HOME}}"/.smk_confs/prerun.sh && -x "${{HOME}}"/.smk_confs/postrun.sh ]]; then
	## now run in full strict mode and do not allow empty variables
	set -euo pipefail

	## source by prefix . else env variable may not get exported to the parent script
	. "${{HOME}}"/.smk_confs/prerun.sh

	echo "BGN at $(date)"
	########################### START SNAKEMAKE CMD ############################
	{exec_job}
	############################ END SNAKEMAKE CMD #############################
	## exitstat must be exported immediately after SNAKEMAKE CMD
	## exitstat will be used in postrun.sh
	exitstat=$?
	export exitstat

	echo "END at $(date)"

	#### NOTE ####
	## postrun.sh is of a little use with snakemake because snakemake runs in
	## strict mode and hence, will exit the moment there is an error.

	## source by prefix . else env variable may not get exported to the parent script
	. "${{HOME}}"/.smk_confs/postrun.sh
else
    ## this may not load complete user env, including user profile.d configs
    set -euo pipefail && \
    {exec_job}
fi

ENDSMAKE=$(date +%d%b%y_%H%M%S_%Z)
printf '\nLOGGER\t%s\tSNAKEMAKE END\n' "${{ENDSMAKE}}"

## disable bash debug
## set +x

## END ##
