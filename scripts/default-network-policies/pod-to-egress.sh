#!/bin/bash

NAMESPACE="tenant-a"
FRONTEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=frontend-service -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=backend-service -o jsonpath='{.items[0].metadata.name}')

while true; do
    echo "Simulating traffic from frontend pod ${FRONTEND_POD} to the internet"
    echo "sending request ..."
    if kubectl exec -n ${NAMESPACE} ${FRONTEND_POD} -- curl -s -o /dev/null https://www.google.com; then
        echo "frontend pod from namespace ${NAMESPACE} can talk to the internet"
    else
        echo "frontend pod from namespace ${NAMESPACE} cannot talk to the internet"
    fi
    sleep 4 

    echo "Simulating traffic from backend pod ${BACKEND_POD} to the internet"
    echo "sending request ..."
    if kubectl exec -n ${NAMESPACE} ${BACKEND_POD} -- curl -s -o /dev/null https://www.google.com; then
        echo "backend pod from namespace ${NAMESPACE} can talk to the internet"
    else
        echo "backend pod from namespace ${NAMESPACE} cannot talk to the internet"
    fi
    sleep 4 
done