#!/bin/bash

## execute after running each of snakemake job
echo 'Running postrun.sh'

## pass envrionment variables and bash confligs on-the-fly while job is running
if [[ -s "${HOME}"/bin/flowrvars_loop.sh ]]; then
        # source by prefix . else env variable may not get exported to parent script
    . "${HOME}"/bin/flowrvars_loop.sh
fi

# notify slack if error or when env variable PINGENDSLACK is set to YES
FORCESTOPSLACK=${FORCESTOPSLACK:-"NO"}

if [[ "${FORCESTOPSLACK}" == "YES" ]]; then
	## exitstat variable comes from jobscript.sh
    WARNMSG="MYJOB ID: $PBS_JOBID exited in $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}."
    echo -e "\n${WARNMSG}\n" >&2
elif [[ ${exitstat} != 0 && -x "${HOME}"/bin/pingme ]] || [[ ${exitstat} != 0 && "${PINGENDSLACK}" == "YES" && -x "${HOME}"/bin/pingme ]]; then
    ERRMSG="MYJOB ID: $PBS_JOBID: $PBS_JOBNAME failed at $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}."

    # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
    #ssh helix ""${HOME}"/bin/pingme -i warning -m "\"${ERRMSG}\""" >> /dev/null 2>&1 &
    "${HOME}"/bin/pingme -i warning -m "${ERRMSG}" >> /dev/null 2>&1 &
    sleep 5

    echo -e "\n${ERRMSG}\n" >&2
elif [[ ${exitstat} == 0 && "${PINGENDSLACK}" == "YES" && -x "${HOME}"/bin/pingme ]]; then
    PASSMSG="MYJOB ID: $PBS_JOBID: $PBS_JOBNAME completed at $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}."

    #ssh helix ""${HOME}"/bin/pingme -i white_check_mark -m "\"${PASSMSG}\""" >> /dev/null 2>&1 &
    "${HOME}"/bin/pingme -i white_check_mark -m "${PASSMSG}" >> /dev/null 2>&1 &
    sleep 5

    echo -e "\n${PASSMSG}\n" >&2
fi

## END ##
