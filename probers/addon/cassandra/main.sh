#!/bin/bash

set -o errexit -o nounset -o pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

function check_cassandra() {
    for i in $(kubectl get pod | grep addon-cassandra | awk '{print $1}')
    do
        if ! (kubectl get pod $i ) | tail -n 1 | grep -i running | grep "1/1" >/dev/null 2>/dev/null ; then
          report-status --name=cassandra_check --status=error --message="cassandra_check error node:$i is not running"
          return 1
        fi

        status=$(kubectl  exec -it $i nodetool status | grep rack | awk '{print $1}' | sort | uniq)
        if [[ $status !=  "UN" ]]; then
          report-status --name=cassandra_check --status=error --message="cassandra_check error node:$i have some peer node down"
          return 1
        fi
    done
    report-status --name=cassandra_check --status=ok
}

if kubectl get cm dice-cluster-info -o yaml | grep DICE_IS_EDGE: | grep false>/dev/null 2>/dev/null; then
  check_cassandra
fi