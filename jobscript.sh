#!/bin/bash

## enable bash debug
# set -x

## Set PS1 to non-empty, even in non-interactive session
## so that user bashrc configs can load.
## see workaround below for details
PS1=\"$-\" && export PS1

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

## snakemake requires additional set of curly braces for bash env variables
if [ -f "${{HOME}}"/.bashrc ]; then
    ## must wait for bashrc to load before snankemake can run
    ## then set full bash strict mode
    ## exec_job is a python variable: marked by a single set of curly braces
    . "${{HOME}}"/.bashrc && \
    sleep 2 && \
    set -euo pipefail && \
    {exec_job}
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

## end ##
