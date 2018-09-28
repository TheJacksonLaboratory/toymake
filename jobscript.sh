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
    ## sleep for n seconds before running any command
    FORCEWAIT=$(shuf -i 5-30 -n 1)
    echo -e "Waiting for ${{FORCEWAIT}} seconds before starting workflow"
    sleep "${{FORCEWAIT}}"

    ## pass envrionment variables and bash confligs on-the-fly while job is running
    ## EDIT: User flowvars, if present in "${{HOME}}"/bin/flowrvars.sh will 
    ## take precedence over default one
    if [[ -s "${{HOME}}"/bin/flowrvars.sh ]]; then
            # source by prefix . else env variable may not get exported to parent script
        . "${{HOME}}"/bin/flowrvars.sh
    elif [[ -s "${{RVSETENV}}"/bin/flowrvars.sh ]]; then
            # source by prefix . else env variable may not get exported to parent script
        . "${{RVSETENV}}"/bin/flowrvars.sh
    fi

    printf "\n####\nPINGSTARTSLACK exported as %s\nPINGENDSLACK exported as %s\n####\n" "${{PINGSTARTSLACK:-NO}}" "${{PINGENDSLACK:-NO}}"

    ## notify slack when job starts if env variable PINGSTARTSLACK is set to YES
    STARTMSG="MYJOB ID: $PBS_JOBID starting at $(pwd) on $(hostname) at $(date) for ${{USER}}"

    if [[ "${{PINGSTARTSLACK}}" == "YES" && -x "${{HOME}}"/bin/pingme ]]; then
        # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
        ssh helix "${{HOME}}/bin/pingme -i white_check_mark -m "\"${{STARTMSG}}\""" >> /dev/null 2>&1 &
        sleep 5
        echo -e "\n${{STARTMSG}}\n"
    elif [[ "${{PINGSTARTSLACK}}" == "YES" ]]; then
        # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
        ssh helix "${{RVSETENV}}/bin/pingme -i white_check_mark -m "\"${{STARTMSG}}\""" >> /dev/null 2>&1 &
        sleep 5
        echo -e "\n${{STARTMSG}}\n"   
    fi

    echo "BGN at $(date)"
    
    {exec_job} 
    
    exitstat=$?

    echo "END at $(date)"

    # notify slack if error or when env variable PINGENDSLACK is set to YES
    FORCESTOPSLACK=${{FORCESTOPSLACK:-"NO"}}

    if [[ "${{FORCESTOPSLACK}}" == "YES" ]]; then
        WARNMSG="MYJOB ID: $PBS_JOBID exited in $(pwd) on $(hostname) for ${{USER}} with exit status: ${{exitstat}}."
        echo -e "\n${{WARNMSG}}\n" >&2
    elif [[ ${{exitstat}} != 0 && -x "${{RVSETENV}}"/bin/pingme ]] || [[ ${{exitstat}} != 0 && "${{PINGENDSLACK}}" == "YES" && -x "${{RVSETENV}}"/bin/pingme ]]; then
        ERRMSG="MYJOB ID: $PBS_JOBID failed at $(pwd) on $(hostname) for ${{USER}} with exit status: ${{exitstat}}."

        # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
        if [[ -s "${{HOME}}"/bin/pingme && -x "${{HOME}}"/bin/pingme ]]; then
            ssh helix ""${{HOME}}"/bin/pingme -i warning -m "\"${{ERRMSG}}\""" >> /dev/null 2>&1 &
            sleep 5
        else
            ssh helix ""${{RVSETENV}}"/bin/pingme -i warning -m "\"${{ERRMSG}}\""" >> /dev/null 2>&1 &
            sleep 5
        fi

        echo -e "\n${{ERRMSG}}\n" >&2
    elif [[ ${{exitstat}} == 0 && "${{PINGENDSLACK}}" == "YES" && -x "${{RVSETENV}}"/bin/pingme ]]; then
        PASSMSG="MYJOB ID: $PBS_JOBID completed at $(pwd) on $(hostname) for ${{USER}} with exit status: ${{exitstat}}."

        # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
        if [[ -s "${{HOME}}"/bin/pingme && -x "${{HOME}}"/bin/pingme ]]; then
            ssh helix ""${{HOME}}"/bin/pingme -i white_check_mark -m "\"${{PASSMSG}}\""" >> /dev/null 2>&1 &
            sleep 5
        else
            ssh helix ""${{RVSETENV}}"/bin/pingme -i white_check_mark -m "\"${{PASSMSG}}\""" >> /dev/null 2>&1 &
            sleep 5
        fi

        echo -e "\n${{PASSMSG}}\n" >&2
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

## end ##
