#!/bin/bash

# scenario to test the to-dns-only policy

NAMESPACE="tenant-a"
FRONTEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=frontend-service -o jsonpath='{.items[0].metadata.name}')

echo "Applying policy ..."
kubectl apply -n $NAMESPACE -f to-dns-only.yaml

echo "DNS lookup ..."
kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -o /dev/null --max-time 2 -s http://backend-service:80
CURL_RC=$?
echo "curl exit code: $CURL_RC"

if [ "$CURL_RC" -eq 28 ]; then
    echo "DNS lookup succeeded"
else
    echo "DNS lookup failed"
fi

echo "Internet access ..."
kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -o /dev/null --max-time 2 -s http://backend-service:80 || echo "expected: failed"

echo "undoing the policy ..."
kubectl delete -n $NAMESPACE ciliumnetworkpolicy to-dns-only
echo "Test done."