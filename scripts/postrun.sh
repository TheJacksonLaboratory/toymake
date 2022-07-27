#!/bin/bash

## @sbamin
## Sumner HPC at JAX

#### NOTE ####
## postrun.sh is of a little use with snakemake because snakemake runs in
## strict mode and hence, will exit the moment commands in the rule were
## completed with or without an error.
## See snakemake/snakemake/executors/__init__.py at
## self.exec_job += " && exit 0 || exit 1" at https://git.io/JUgqE

## execute after running each of snakemake job using jobscript.sh
MYJOBEND="$(date +%d%b%y_%H%M%S_%Z)"
echo 'Running slurm postrun.sh on HPC SUMNER VERSION: ${SUM7VERSION}'

## jobscript.sh must export an env variable "exitstat" immediately after
## running user commands in the respective snakemake rule else emit warning.
exitstat="${exitstat:-"WARN"}"

if [[ "$exitstat" == "WARN" ]]; then
  printf "LOGGER\t%s\tWARN: FAILED TO CAPTURE A VALID EXIT CODE\n" "${MYJOBEND}" >&2
fi

ENDMSG="$(printf "LOGGER\t%s\tEND: %s\t%s\t%s\t%s\t%s\t%s\n" "${MYJOBEND}" "${exitstat}" "${SLURM_JOB_ID}" "${SLURM_JOB_NAME}" "$(pwd)" "${SLURMD_NODENAME}" "${USER}")"

## notify slack only on error unless stated otherwise from prerun.sh
## exported variables
PINGENDSLACK="${PINGENDSLACK:-"NO"}"
FORCESTOPSLACK="${FORCESTOPSLACK:-"NO"}"

## notify slack if error
if [[ "${FORCESTOPSLACK}" == "YES" ]]; then
    echo -e "\n${ENDMSG}\n"
elif [[ "${exitstat}" != "0" && -x "${HOME}"/bin/pingme ]]; then
    # allow 5 seconds before exit of parent script so job can ping slack
    "${HOME}"/bin/pingme -u "${USER}" -i warning -m "${ENDMSG}" >> /dev/null 2>&1 &
    sleep 5
    echo -e "\n${ENDMSG}\n"
elif [[ "${exitstat}" == "0" && "${PINGENDSLACK}" == "YES" && -x "${HOME}"/bin/pingme ]]; then
    # allow 5 seconds before exit of parent script so job can ping slack
    "${HOME}"/bin/pingme -u "${USER}" -i warning -m "${ENDMSG}" >> /dev/null 2>&1 &
    sleep 5
    echo -e "\n${ENDMSG}\n"
fi

echo "exit status was ${exitstat}"

## If postrun.sh fails to capture exitstat from snakemake commands,
## exit with zero as snakemake runs in strict mode and should capture
## valid exit status. However, check for WARN message in LOGGER.
if [[ "${exitstat}" == "0" || "${exitstat}" == "WARN" ]]; then
  exit 0
else
  exit "${exitstat}"
fi

## END ##
