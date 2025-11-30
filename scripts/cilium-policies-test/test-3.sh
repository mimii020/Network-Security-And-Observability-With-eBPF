#!/bin/bash

# scenario to test the allow-all-within-ns and allow-frontend-to-hackend-policy

NAMESPACE="tenant-a"
FRONTEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=frontend-service -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=backend-service -o jsonpath='{.items[0].metadata.name}')
FRONTEND_SERVICE="frontend-service"
BACKEND_SERVICE="backend-service"

echo "Applying policy ..."
kubectl apply -n $NAMESPACE -f allow-all-within-ns.yaml
sleep 4
echo "Appied allow-all-within-ns policy, all trafic within the ${NAMESPACE} namespace should be allowed"

echo "Applying policy ..."
kubectl apply -n $NAMESPACE -f to-dns-only.yaml
sleep 4
echo "Appied to-dns-only policy, dns trafic within the ${NAMESPACE} namespace should be allowed"

kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -o /dev/null --max-time 2 -s http://${BACKEND_SERVICE}:80 && echo "Succeeded as expected"
kubectl exec -n $NAMESPACE $BACKEND_POD -- curl -s http://${FRONTEND_SERVICE}:80 > /dev/null && echo "Succeeded as expected"

kubectl delete -n $NAMESPACE ciliumnetworkpolicy allow-all-within-ns-policy
sleep 4
echo "deleted allow-all-within-ns policy"

# testing trafic between the frntend and the backend pod in the tenant-a namespace
echo "Applying policy ..."
kubectl apply -n $NAMESPACE -f allow-frontend-to-backend-only.yaml
sleep 4 
echo "Appied allow-frontend-to-backend-only policy, only trafic from the frontend pod should be allowed in the backend pod"

echo "Applying policy ..."
kubectl apply -n $NAMESPACE -f only-http-from-frontend.yaml
sleep 4
echo "Appied only-http-from-frontend policy, only http egress trafic from the frontend pod within the ${NAMESPACE} namespace should be allowed"

echo "testing trafic from frontend to backend pod"
kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -o /dev/null -sv http://${BACKEND_SERVICE}:80/public && echo "Succeeded as expected"

echo "testing trafic from backend to frontend pod"
kubectl exec -n $NAMESPACE $BACKEND_POD -- curl -sv http://${FRONTEND_SERVICE}:80/public > /dev/null && echo "Succeeded as expected"

# testing trafic from a non-frontend pod to the backend pod
kubectl -n tenant-a run test-pod --image=busybox --restart=Never -- sleep 3600
NON_FRONTEND_POD=$(kubectl -n tenant-a get pods -l run=test-pod -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n $NAMESPACE $NON_FRONTEND_POD -- curl -o /dev/null -sv http://${BACKEND_SERVICE}:80/public || echo "Failed as expected"

kubectl delete -n $NAMESPACE ciliumnetworkpolicy allow-frontend-to-backend-only
echo "deleted allow-frontend-to-backend-only policy"
sleep 4

kubectl delete -n $NAMESPACE ciliumnetworkpolicy to-dns-only
echo "deleted to-dns-only policy"
sleep 4

kubectl delete -n $NAMESPACE ciliumnetworkpolicy only-http-from-frontend
echo "deleted only-http-from-frontend policy"
sleep 4

echo "Test done."