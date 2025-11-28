#!/bin/bash

# scenario to test allow-all then allow-frontend-to-backend policies

NAMESPACE="tenant-a"
FRONTEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=frontend-service -o jsonpath='{.items[0].metadata.name}')

kubectl apply -n $NAMESPACE -f deny-all.yaml
sleep 2
echo "Appied deny all policy, all trafic should be denied"
kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -o /dev/null --max-time 2 -s http://backend-service:80 || echo "Failed as expected"
sleep 4

kubectl apply -n $NAMESPACE -f to-dns-only.yaml
sleep 2
echo "Appied to dns only policy, dns trafic should be allowed"
sleep 4

kubectl apply -n $NAMESPACE -f allow-frontend-to-backend-only.yaml
sleep 2
echo "Applied allow frontend to backend only policy"
kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -o /dev/null --max-time 2 -s http://backend-service:80/public || echo "Failed as expected"
sleep 4

echo "undoing the policies ..."
kubectl delete -n $NAMESPACE ciliumnetworkpolicy deny-all
sleep 2
echo "deleted deny-all policy"
kubectl delete -n $NAMESPACE ciliumnetworkpolicy allow-frontend-to-backend-only
sleep 2
echo "deleted to-dns-only policy"
kubectl delete -n $NAMESPACE ciliumnetworkpolicy to-dns-only
sleep 2
echo "deleted to-dns-only policy"

echo "Test done."