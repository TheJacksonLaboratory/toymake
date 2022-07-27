#!/bin/bash

## @sbamin
## Sumner HPC at JAX

## execute prior to running each of snakemake job
MYJOBSTART="$(date +%d%b%y_%H%M%S_%Z)"

echo "Running slurm prerun.sh on HPC SUMNER VERSION: ${SUM7VERSION}"

## sleep for n seconds before running any command
FORCEWAIT=$(shuf -i 5-30 -n 1)
echo -e "Waiting for ${FORCEWAIT} seconds before starting workflow"
sleep "${FORCEWAIT}"

## pass envrionment variables and bash confligs on-the-fly while job is running
## source default hpcvars.sh
if [[ -s "${HOME}"/.hpc_confs/hpcvars.sh && -x "${HOME}"/.hpc_confs/hpcvars.sh ]]; then
    # source by prefix . else env variable may not get exported to parent script
    . "${HOME}"/.hpc_confs/hpcvars.sh
else
	## disable slack notifications
	PINGSTARTSLACK="${PINGSTARTSLACK:-NO}"
	FORCESTOPSLACK=${FORCESTOPSLACK:-NO}
	PINGENDSLACK="${PINGENDSLACK:-NO}"
fi

printf "####\nPINGSTARTSLACK exported as %s\nPINGENDSLACK exported as %s\n####\n" "${PINGSTARTSLACK}" "${PINGENDSLACK}"

## notify slack when job starts if env variable PINGSTARTSLACK is set to YES
STARTMSG="$(printf "LOGGER\t%s\tSTART\t%s\t%s\t%s\t%s\t%s\n" "${MYJOBSTART}" "${SLURM_JOB_ID}" "${SLURM_JOB_NAME}" "$(pwd)" "${SLURMD_NODENAME}" "${USER}")"

if [[ "${PINGSTARTSLACK}" == "YES" && -x "${HOME}"/bin/pingme ]]; then
    # allow 5 seconds before exit of parent script so job can ping slack
    "${HOME}"/bin/pingme -u "${USER}" -i "hourglass_flowing_sand" -m "${STARTMSG}" >> /dev/null 2>&1 &
    sleep 5
    echo -e "\n${STARTMSG}\n"
else
	echo -e "\n${STARTMSG}\n"
fi

## This will be system default unless overridden by an user
echo "TMPDIR is ${TMPDIR}"

export MYJOBSTART PINGENDSLACK FORCESTOPSLACK
## END ##
