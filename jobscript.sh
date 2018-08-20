#!/bin/bash

## enable strict error check
## but allow empty variables
## Read http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eo pipefail

# following will always overwrite previous output file, if any. 
set +o noclobber

########## workaround to source bashrc and user env ##########
## If snankemake is running in non-interactive bash mode,
## allow an exception to load bashrc (and profile.d) settings
## Read more into ~/.bashrc header under PS1 variable

## snakemake requires additional set of curly braces for bash env variables
if [ -f "${{HOME}}"/.bashrc ]; then
    ## export SMKFLOW variable which will be used in ~/.bashrc
    SMKFLOW="ACTIVE"
    export SMKFLOW

    ## must wait for bashrc to load before snankemake can run
    ## exec_job is a python variable: marked by a single set of curly braces
  . "${{HOME}}"/.bashrc && sleep 2 && {exec_job}

    ## post-completion commands
    echo 'job done'
else
    ## this may not load complete user env, including user profile.d configs
    {exec_job}
fi

## end ##
