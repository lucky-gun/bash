#!/bin/bash

print_header() {
	echo "======================="
	echo "Kubernetes Health Check"
        echo "======================="
}

check_nodes() {
	echo ""
    	echo "[Node Status]"

	kubectl get nodes --no-headers
}

check_crashloop() {

    echo ""
    echo "[CrashLoop Pods]"

    CRASH=$(kubectl get pods -A | grep CrashLoopBackOff)

    if [ -z "$CRASH" ]
    then
        echo "없음"
    else
        echo "$CRASH"
    fi
}

check_pending() {

    echo ""
    echo "[Pending Pods]"

    PENDING=$(kubectl get pods -A | grep Pending)

    if [ -z "$PENDING" ]
    then
        echo "없음"
    else
        echo "$PENDING"
    fi
}

print_header
check_nodes
check_crashloop
check_pending
