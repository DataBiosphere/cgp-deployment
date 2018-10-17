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

    # Get array of all necessary containers from file.
    fname=~/cgp-deployment/test/expected_containers
    IFS=$'\r\n' GLOBIGNORE='*' command eval  'containers_expected=($(cat $fname))'
    containers_expected=($containers_expected)  # cast as array

    num_containers_exp="${#containers_expected[@]}"

    # Crude initial test to verify that at least 7 containers are running.
    [ "${#containers[@]}" -ge $num_containers_exp ] ||\
        (ERROR "Not running the required number of docker containers." && exit 1)

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
            ERROR "One or more docker containers not running." && exit 1
        fi
    done

}

function main {
    check_setup
    cd "$(dirname "${BASH_SOURCE[0]}")"
    LOG_LEVEL_ALL

    [[ -d outputs ]] && sudo rm -rf outputs && INFO "deleted old outputs"

    # access_token=$(../redwood/cli/bin/redwood token create)
    # INFO "generated testing access token: ${access_token}"

    # redwood_endpoint=$(cat ../redwood/.env | grep 'base_url=' | sed 's/[^=]*=//')
    # INFO "got redwood endpoint from dcc-ops/redwood/.env: ${redwood_endpoint}"

    # INFO "doing upload with $(pwd)/manifest.tsv"
    # sudo docker run --rm -it -e ACCESS_TOKEN=${access_token} -e REDWOOD_ENDPOINT=${redwood_endpoint} \
    #      -v $(pwd)/manifest.tsv:/dcc/manifest.tsv -v $(pwd)/samples:/samples -v $(pwd)/outputs:/outputs \
    #      quay.io/ucsc_cgl/core-client:1.1.0-alpha spinnaker-upload --skip-submit --force-upload /dcc/manifest.tsv

    # object_id=$(cat outputs/receipt.tsv | tail -n +3 | head -n 1 | cut -f 20)
    # bundle_id=$(cat outputs/receipt.tsv | tail -n +3 | head -n 1 | cut -f 19)
    # INFO "the uploaded bundle with id ${bundle_id} has metadata.json with object id ${object_id}"

    # INFO "downloading metadata.json with object id ${object_id}"
    # sudo mkdir outputs/test_download
    # sudo docker run --rm -it -e ACCESS_TOKEN=${access_token} -e REDWOOD_ENDPOINT=${redwood_endpoint} \
    #      -v $(pwd)/outputs:/outputs quay.io/ucsc_cgl/core-client:1.1.0-alpha download ${object_id} /outputs/test_download

    # [[ ! -f outputs/test_download/${bundle_id}/metadata.json ]] && printf "%s: no such file" "outputs/test_download/${bundle_id}/metadata.json" | FATAL && exit 1

    # sudo rm -rf outputs

    # # TODO: run indexer, etc.

    INFO "TEST SUCCEEDED"
}

main "$@"
