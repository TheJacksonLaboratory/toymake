#!/bin/bash

## enable bash debug
# set -x

## enable strict error check
## allow empty variables until user bashrc has been loaded
## for PS1, PROMPT_COMMAND, etc.
## Read http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eo pipefail

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

## snakemake requires additional set of curly braces for bash env variables
if [ -f "${{HOME}}"/.bashrc ]; then
	## now do not allow empty variables
    set -euo pipefail

	if [[ -s "${{HOME}}"/.smk_confs/prerun.sh ]]; then
	        # source by prefix . else env variable may not get exported to parent script
	    . "${{HOME}}"/.smk_confs/prerun.sh
	fi

    echo "BGN at $(date)"
	########################### START SNAKEMAKE CMD ############################
    {exec_job} 
	############################ END SNAKEMAKE CMD #############################  
    exitstat=$?
    export exitstat

    echo "END at $(date)"

	if [[ -s "${{HOME}}"/.smk_confs/postrun.sh ]]; then
	        # source by prefix . else env variable may not get exported to parent script
	    . "${{HOME}}"/.smk_confs/postrun.sh
	fi
else
    ## this may not load complete user env, including user profile.d configs
    set -euo pipefail && \
    {exec_job}
fi

##### Exit with a valid exit status #####
exitstat=$?
TSTAMP=$(date +%d%b%y_%H%M%S%Z)
printf 'exit_status\tT:%s\tE:%s' "${{TSTAMP}}" "${{exitstat}}" && \
exit "${{exitstat}}"

## disable bash debug
# set +x

## END ##
