#!/bin/bash

NAMESPACE="tenant-a"
FRONTEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=frontend-service -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=backend-service -o jsonpath='{.items[0].metadata.name}')
FRONTEND_SERVICE="frontend-service"
BACKEND_SERVICE="backend-service"

while true; do
    echo "Simulating traffic from frontend pod ${FRONTEND_POD} to the backend pod in the same ${NAMESPACE} namespace"
    echo "sending request ..."
    if kubectl exec -n ${NAMESPACE} ${FRONTEND_POD} -- curl -s http://${BACKEND_SERVICE}:80 > /dev/null; then
        echo "frontend pod $FRONTEND_POD can talk to backend pod"
    else
        echo "frontend pod cannot talk to backend pod"
    fi
    sleep 4 

    echo "Simulating traffic from frontend pod ${BACKEND_POD} to the frontend pod in the same ${NAMESPACE} namespace"
    echo "sending request ..."
    if kubectl exec -n ${NAMESPACE} ${BACKEND_POD} -- curl -s http://${FRONTEND_SERVICE} > /dev/null; then
        echo "backend pod can talk to frontend pod"
    else
        echo "backend pod cannot talk to frontend pod"
    fi
    sleep 4 
done