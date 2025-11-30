#!/bin/bash

# scenario to test the allow-http-frontend-to-backend policy

NAMESPACE="tenant-a"
FRONTEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=frontend-service -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=backend-service -o jsonpath='{.items[0].metadata.name}')
FRONTEND_SERVICE="frontend-service"
BACKEND_SERVICE="backend-service"

echo "Applying policy ..."
kubectl apply -n $NAMESPACE -f to-dns-only.yaml
sleep 4
echo "Appied to-dns-only policy, all dns trafic within the ${NAMESPACE} namespace should be allowed"

echo "Applying policy ..."
kubectl apply -n $NAMESPACE -f allow-get-block-post.yaml
sleep 4
echo "Appied allow-get-block-post policy, only http GET trafic to the backend pods within the ${NAMESPACE} namespace should be allowed"

echo "Applying policy ..."
kubectl apply -n $NAMESPACE -f only-http-from-frontend.yaml
sleep 4
echo "Appied only-http-from-frontend.yaml policy, only http trafic from the frontend pods to the backend pods within the ${NAMESPACE} namespace should be allowed"

echo "Testing connection from frontend to backend pod using a GET request"
kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -o /dev/null -s http://${BACKEND_SERVICE}:80/public && echo "Succeeded as expected"
echo "Testing connection from backend to frontend pod using a GET request"
kubectl exec -n $NAMESPACE $BACKEND_POD -- curl -s http://${FRONTEND_SERVICE}:80/public > /dev/null && echo "Succeeded as expected"

echo "Testing connection from frontend to backend pod using a POST request"
kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -X POST --fail -d 'x=1' -o /dev/null -s http://${BACKEND_SERVICE}:80/public || echo "Failed as expected"


IMAGE=curlimages/curl
NON_FRONTEND_POD=test-pod            
# create if missing, or recreate if not Running
if ! kubectl -n "$NAMESPACE" get pod "$NON_FRONTEND_POD" >/dev/null 2>&1; then
  echo "Creating $POD..."
  kubectl -n "$NAMESPACE" run "$NON_FRONTEND_POD" --image="$IMAGE" --restart=Never -- /bin/sh -c "sleep 3600"
else
  PHASE=$(kubectl -n "$NAMESPACE" get pod "$NON_FRONTEND_POD" -o jsonpath='{.status.phase}')
  if [ "$PHASE" != "Running" ]; then
    echo "Pod $NON_FRONTEND_POD exists but is $PHASE — recreating..."
    kubectl -n "$NAMESPACE" delete pod "$NON_FRONTEND_POD" --ignore-not-found
    kubectl -n "$NAMESPACE" run "$NON_FRONTEND_POD" --image="$IMAGE" --restart=Never -- /bin/sh -c "sleep 3600"
  else
    echo "Pod $NON_FRONTEND_POD already running."
  fi
fi
# wait until Ready (timeout 60s)
kubectl -n "$NAMESPACE" wait --for=condition=Ready pod/"$NON_FRONTEND_POD" --timeout=60s
echo "Testing connection from a non-frontend to backend pod using a GET request"
kubectl exec -n $NAMESPACE $NON_FRONTEND_POD -- curl --fail -o /dev/null -s http://${BACKEND_SERVICE}:80/public || echo "Failed as expected"

echo "Deleting policies ..."

kubectl delete -n $NAMESPACE ciliumnetworkpolicy allow-get-block-post
echo "deleted allow-get-block-post policy"
sleep 4

kubectl delete -n $NAMESPACE ciliumnetworkpolicy to-dns-only
echo "deleted to-dns-only policy"
sleep 4

kubectl delete -n $NAMESPACE ciliumnetworkpolicy only-http-from-frontend
echo "deleted only-http-from-frontend policy"
sleep 4

echo "Test done."