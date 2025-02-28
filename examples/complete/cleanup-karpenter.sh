#!/bin/bash
# filepath: cleanup-karpenter.sh

echo "Scaling down all deployments..."
kubectl scale deployment --all --all-namespaces --replicas=0

echo "Waiting for pods to terminate..."
sleep 30

echo "Deleting Karpenter NodePools..."
kubectl delete nodepools --all

echo "Waiting for nodes to terminate..."
sleep 120

echo "Proceeding with terraform destroy..."
terraform destroy -auto-approve