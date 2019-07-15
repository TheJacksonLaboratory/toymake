#!/bin/bash

## execute prior to running each of snakemake job
echo 'Running prerun.sh'

## sleep for n seconds before running any command
FORCEWAIT=$(shuf -i 5-30 -n 1)
echo -e "Waiting for ${FORCEWAIT} seconds before starting workflow"
sleep "${FORCEWAIT}"

## pass envrionment variables and bash confligs on-the-fly while job is running
if [[ -s "${HOME}"/bin/flowrvars.sh ]]; then
        # source by prefix . else env variable may not get exported to parent script
    . "${HOME}"/bin/flowrvars.sh
fi

printf "\n####\nPINGSTARTSLACK exported as %s\nPINGENDSLACK exported as %s\n####\n" "${PINGSTARTSLACK:-NO}" "${PINGENDSLACK:-NO}"

## notify slack when job starts if env variable PINGSTARTSLACK is set to YES
STARTMSG="MYJOB ID: $PBS_JOBID starting at $(pwd) on $(hostname) at $(date) for ${USER}"

if [[ "${PINGSTARTSLACK}" == "YES" && -x "${HOME}"/bin/pingme ]]; then
    # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
    ssh helix "${HOME}/bin/pingme -i white_check_mark -m "\"${STARTMSG}\""" >> /dev/null 2>&1 &
    sleep 5
    echo -e "\n${STARTMSG}\n"
fi

export PINGENDSLACK FORCESTOPSLACK
## END ##
