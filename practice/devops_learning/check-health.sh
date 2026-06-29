#!/bin/bash

check_restart_count() {

	echo ""
	echo "[High Restart Pods]"

	kubectl get pods -A -o json \
	| jq -r '
	.items[]
	| select(.status.containerStatuses != null)
	| select(.status.containerStatuses[0].restartCount >= 10)
	| [.metadata.namespace, .metadata.name, .status.containerStatuses[0].restartCount]
	| @tsv'

}

get_ready_nodes() {

    READY_NODES=$(
        kubectl get nodes -o json \
	| jq '[
	    .items[]
	    | select(
		any(
		  .status.conditions[];
		  .type == "Ready" and .status == "True"
		)
	    )
	]
	| length'
    )

    TOTAL_NODES=$(
	kubectl get nodes -o json |
	jq '.items | length'
    )
}

get_running_pods() {

    RUNNING_PODS=$(
        kubectl get pods -A -o json \
        | jq '[
            .items[]
            | select(.status.phase=="Running")
        ]
        | length'
    )

}

get_high_restart_pods() {

    HIGH_RESTART_PODS=$(
        kubectl get pods -A -o json \
        | jq '[
            .items[]
            | select(.status.containerStatuses != null)
	    | select(.status.containerStatuses[0].restartCount >= 10)
        ]
        | length'
    )

}

get_crashloop_pods() {

    CRASHLOOP_PODS=$(
        kubectl get pods -A -o json \
        | jq '[
            .items[]
            | select(.status.containerStatuses != null)
	    | select(.status.containerStatuses[0].state.waiting?.reason == "CrashLoopBackOff")
        ]
        | length'
    )

}

evaluate_status() {

	STATUS="PASS"
	
	if [ "$CRASHLOOP_PODS" -gt 0 ]
	then
		STATUS="FAIL"
	elif [ "$READY_NODES" -ne "$TOTAL_NODES" ]
	then
		STATUS="FAIL"
	fi

}

print_report() {

    echo "================================="
    echo " Kubernetes Health Report"
    echo "================================="
    echo

    printf "[INFO] Ready Nodes	: %s/%s\n" "$READY_NODES" "$TOTAL_NODES"

    printf "[INFO] Running Pods	: %s\n" \
        "$RUNNING_PODS"

    printf "[WARN] High Restart Pods : %s\n" \
        "$HIGH_RESTART_PODS"

    printf "[ERROR] CrashLoop Pods   : %s\n" \
        "$CRASHLOOP_PODS"

    echo
    echo "Status : $STATUS"
}

set -euo pipefail

main() {
	#check_restart_count
	get_ready_nodes
	get_running_pods
	get_high_restart_pods
	get_crashloop_pods
	evaluate_status
	print_report
}

main



