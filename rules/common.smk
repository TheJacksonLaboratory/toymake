################################### STARTUP ####################################
onstart:
    shell:"""
        # following will always overwrite previous output file, if any. 
        set +o noclobber

        ## sleep for n seconds before running any command
        FORCEWAIT=$(shuf -i 5-30 -n 1)
        echo -e "Waiting for ${FORCEWAIT} seconds before starting workflow"
        sleep "${FORCEWAIT}"

        ## pass envrionment variables and bash confligs on-the-fly while job is running
        ## EDIT: User flowvars, if present in "${HOME}"/bin/flowrvars.sh will 
        ## take precedence over default one
        if [[ -s "${HOME}"/bin/flowrvars.sh ]]; then
                # source by prefix . else env variable may not get exported to parent script
            . "${HOME}"/bin/flowrvars.sh
        elif [[ -s "${RVSETENV}"/bin/flowrvars.sh ]]; then
                # source by prefix . else env variable may not get exported to parent script
            . "${RVSETENV}"/bin/flowrvars.sh
        fi

        printf "\n####\nPINGSTARTSLACK exported as %s\nPINGENDSLACK exported as %s\n####\n" "${PINGSTARTSLACK:-NO}" "${PINGENDSLACK:-NO}"

        ## notify slack when job starts if env variable PINGSTARTSLACK is set to YES
        STARTMSG="MYJOB ID: {jobid}_{rule} starting at $(pwd) on $(hostname) at $(date) for ${USER}"

        if [[ "${PINGSTARTSLACK}" == "YES" && -x "${HOME}"/bin/pingme ]]; then
            # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
            ssh helix "${HOME}/bin/pingme -i white_check_mark -m "\"${STARTMSG}\""" >> /dev/null 2>&1 &
            sleep 5
            echo -e "\n${STARTMSG}\n"
        elif [[ "${PINGSTARTSLACK}" == "YES" ]]; then
            # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
            ssh helix "${RVSETENV}/bin/pingme -i white_check_mark -m "\"${STARTMSG}\""" >> /dev/null 2>&1 &
            sleep 5
            echo -e "\n${STARTMSG}\n"   
        fi

        echo "BGN at $(date)"
        """

##################################### END ######################################
onsuccess:
    shell:"""
        exitstat=$?

        echo "END at $(date)"

        # notify slack if error or when env variable PINGENDSLACK is set to YES
        FORCESTOPSLACK=${FORCESTOPSLACK:-"NO"}

        if [[ "${FORCESTOPSLACK}" == "YES" ]]; then
            WARNMSG="MYJOB ID: {jobid}_{rule} exited in $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}. Log file is at {log}"
            echo -e "\n${WARNMSG}\n" >&2
        elif [[ ${exitstat} != 0 && -x "${RVSETENV}"/bin/pingme ]] || [[ ${exitstat} != 0 && "${PINGENDSLACK}" == "YES" && -x "${RVSETENV}"/bin/pingme ]]; then
            ERRMSG="MYJOB ID: {jobid}_{rule} failed at $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}. Log file is at {log}"

            # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
            if [[ -s "${HOME}"/bin/pingme && -x "${HOME}"/bin/pingme ]]; then
                ssh helix ""${HOME}"/bin/pingme -i warning -m "\"${ERRMSG}\""" >> /dev/null 2>&1 &
                sleep 5
            else
                ssh helix ""${RVSETENV}"/bin/pingme -i warning -m "\"${ERRMSG}\""" >> /dev/null 2>&1 &
                sleep 5
            fi

            echo -e "\n${ERRMSG}\n" >&2
        elif [[ ${exitstat} == 0 && "${PINGENDSLACK}" == "YES" && -x "${RVSETENV}"/bin/pingme ]]; then
            PASSMSG="MYJOB ID: {jobid}_{rule} completed at $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}. Log file is at {log}"

            # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
            if [[ -s "${HOME}"/bin/pingme && -x "${HOME}"/bin/pingme ]]; then
                ssh helix ""${HOME}"/bin/pingme -i white_check_mark -m "\"${PASSMSG}\""" >> /dev/null 2>&1 &
                sleep 5
            else
                ssh helix ""${RVSETENV}"/bin/pingme -i white_check_mark -m "\"${PASSMSG}\""" >> /dev/null 2>&1 &
                sleep 5
            fi

            echo -e "\n${PASSMSG}\n" >&2
        fi
        """

onerror:
    shell:"""
        exitstat=$?

        echo "END at $(date)"

        # notify slack if error or when env variable PINGENDSLACK is set to YES
        FORCESTOPSLACK=${FORCESTOPSLACK:-"NO"}

        if [[ "${FORCESTOPSLACK}" == "YES" ]]; then
            WARNMSG="MYJOB ID: {jobid}_{rule} exited in $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}. Log file is at {log}"
            echo -e "\n${WARNMSG}\n" >&2
        elif [[ ${exitstat} != 0 && -x "${RVSETENV}"/bin/pingme ]] || [[ ${exitstat} != 0 && "${PINGENDSLACK}" == "YES" && -x "${RVSETENV}"/bin/pingme ]]; then
            ERRMSG="MYJOB ID: {jobid}_{rule} failed at $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}. Log file is at {log}"

            # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
            if [[ -s "${HOME}"/bin/pingme && -x "${HOME}"/bin/pingme ]]; then
                ssh helix ""${HOME}"/bin/pingme -i warning -m "\"${ERRMSG}\""" >> /dev/null 2>&1 &
                sleep 5
            else
                ssh helix ""${RVSETENV}"/bin/pingme -i warning -m "\"${ERRMSG}\""" >> /dev/null 2>&1 &
                sleep 5
            fi

            echo -e "\n${ERRMSG}\n" >&2
        elif [[ ${exitstat} == 0 && "${PINGENDSLACK}" == "YES" && -x "${RVSETENV}"/bin/pingme ]]; then
            PASSMSG="MYJOB ID: {jobid}_{rule} completed at $(pwd) on $(hostname) for ${USER} with exit status: ${exitstat}. Log file is at {log}"

            # keep ssh into background but allow 5 seconds before exit of parent script so ssh job can ping slack
            if [[ -s "${HOME}"/bin/pingme && -x "${HOME}"/bin/pingme ]]; then
                ssh helix ""${HOME}"/bin/pingme -i white_check_mark -m "\"${PASSMSG}\""" >> /dev/null 2>&1 &
                sleep 5
            else
                ssh helix ""${RVSETENV}"/bin/pingme -i white_check_mark -m "\"${PASSMSG}\""" >> /dev/null 2>&1 &
                sleep 5
            fi

            echo -e "\n${PASSMSG}\n" >&2
        fi
        """

## end ##
