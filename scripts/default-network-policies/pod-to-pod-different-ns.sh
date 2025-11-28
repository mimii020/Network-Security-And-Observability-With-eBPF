#!/bin/bash

NAMESPACE_1="tenant-a"
NAMESPACE_2="tenant-b"
FRONTEND_POD=$(kubectl get pod -n ${NAMESPACE_1} -l app=frontend-service -o jsonpath='{.items[0].metadata.name}')
BACKEND_SERVICE="backend-service"

echo "Simulating traffic from frontend pod ${FRONTEND_POD} to the backend pod in different namespaces"
while true; do
    echo "sending request ..."
    if kubectl exec -n ${NAMESPACE_1} ${FRONTEND_POD} -- curl -s http://${BACKEND_SERVICE}.${NAMESPACE_2}.svc.cluster.local:80 > /dev/null; then
        echo "frontend pod from namespace ${NAMESPACE_1} can talk to backend pod from namespace ${NAMESPACE_2}"
    else
        echo "frontend pod from namespace ${NAMESPACE_1} cannot talk to backend pod from namespace ${NAMESPACE_2}"
    fi
    sleep 4 
done