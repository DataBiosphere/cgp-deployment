#!/usr/bin/env bash

set -e  # exit if return is non-zero
# Start logging.
source $(dirname $( realpath ${BASH_SOURCE[0]} ) )/lib/b-log.sh

function check_setup {

    # This function exits the script if:
    #   (i) the number of running Docker is less than
    #       the required number of containers
    #   (ii) not all exact names of required Docker containers
    #        match all names in the list of running Docker containers

    # Get array of running containers.
    containers=($(sudo docker ps | tail -n +2 | awk ' {print $NF} '))

    # Get array of all required containers from file.
    fname=expected_containers
    IFS=$'\r\n' GLOBIGNORE='*'\
       command eval  'containers_expected=($(cat $fname))'
    containers_expected=($containers_expected)  # cast as array

    num_containers_exp="${#containers_expected[@]}"

    # Crude initial test to verify that at least the minimum number of
    # containers are running.
    [ "${#containers[@]}" -ge $num_containers_exp ] ||\
        (ERROR "Not running the required number of docker containers."\
		&& exit 1)

    for container_expected in "${containers_expected[@]}"; do
        counter=0
        for container in "${containers[@]}"; do
            if [[ $container_expected = $container ]]; then
                continue
            else
                counter=$((counter+1))
            fi
        done

        if [[ "$counter" -eq $num_containers_exp ]]; then
            ERROR "One or more docker containers not running."\
		&& exit 1
        fi
    done

}

function main {
    # This tests whether all Docker containers are installed and then
    # hits the DCC Dashboard Host and checks whether it returns a 200
    # status code.

    cd "$(dirname "${BASH_SOURCE[0]}")"
    LOG_LEVEL_ALL
    check_setup

    # Get name of the DCC Dashboard Host.
    curr_dir=$(pwd)
    cd ../boardwalk
    dcc_host=$(grep -o 'dcc_dashboard_service.*' .env | cut -f2- -d=)
    # Check from environment variable value whether user is white-listed.    
    whitelist_set=$(grep -o 'email_white.*' .env | cut -f2- -d=)
    cd "$curr_dir"

    # Check if home page is returned. If so it will not output anything,
    # otherwise it aborts and prints cURL error code to stdout.
    curl -fsS "https://$dcc_host" > /dev/null

    # Get status code of response to export functionality.
    url="https://$dcc_host/api/v1/repository/files/export"
    response=$(curl -sIL "$url")  # no output, just headers, follow redirects
    status_code=$(echo "$response" | grep 'HTTP.*' | cut -f2- -d " ")

    # If the whitelist string is empty user isn't white-listed, and cURL
    # is expected to return 200; if user is white-listed a 401 is the expected
    # response.
    if [[ ! "$status_code" == *"401"* ]] && [[ ! -z "$whitelist_set" ]]; then
        ERROR "Did not get expected status code 401 from host $dcc_host" && exit 1
    elif [[ ! "$status_code" == *"200"* ]]\
	     && [[ ! "$status_code" == *"401"* ]]; then
	ERROR "Did not get expected status code 200 from host $dcc_host" && exit 1
    fi

    INFO "TEST SUCCEEDED"
}

main "$@"
