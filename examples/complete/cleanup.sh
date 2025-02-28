#!/bin/bash
set -euo pipefail

# Check that jq, kubectl, helm, and terraform are installed.
for cmd in jq kubectl helm terraform; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: Command '$cmd' is not installed. Please install it to continue."
    exit 1
  fi
done

echo "===== STARTING CLUSTER RESOURCE CLEANUP ====="

# Phase 1: Application Resource Cleanup

# 1.1 Uninstall the Prometheus Helm release (if it exists) in the 'monitoring' namespace.
echo "Uninstalling 'prometheus-stack' release in the 'monitoring' namespace (if exists)..."
helm uninstall prometheus-stack -n monitoring || echo "The 'prometheus-stack' release does not exist or has already been uninstalled."

# 1.2 Delete all PersistentVolumeClaims (PVCs) in all namespaces.
echo "Deleting all PVCs in all namespaces..."
for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name"); do
  echo "Deleting PVCs in namespace: $ns"
  for pvc in $(kubectl get pvc -n "$ns" --no-headers -o custom-columns=":metadata.name"); do
    echo "Deleting PVC: $pvc in namespace $ns"
    kubectl delete pvc "$pvc" -n "$ns" --ignore-not-found
  done
done

# 1.3 Remove finalizers from stuck PVCs (those in deletion with pending finalizers)
echo "Searching for PVCs in deletion with pending finalizers..."
stuck_pvcs=$(kubectl get pvc --all-namespaces -o json | jq -r '.items[] | select(.metadata.deletionTimestamp != null and (.metadata.finalizers | length) > 0) | "\(.metadata.namespace) \(.metadata.name)"')

if [ -n "$stuck_pvcs" ]; then
  echo "The following PVCs with finalizers were found:"
  echo "$stuck_pvcs"
  while IFS= read -r line; do
    ns=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    echo "Removing finalizers from PVC $name in namespace $ns"
    kubectl patch pvc "$name" -n "$ns" --type=json -p '[{"op": "remove", "path": "/metadata/finalizers"}]' || true
  done <<< "$stuck_pvcs"
else
  echo "No PVCs with pending finalizers were found."
fi

# 1.4 Optional: Clean up Karpenter resources if installed.
echo "Checking for Karpenter installation..."
if kubectl get ns karpenter &> /dev/null; then
  echo "Namespace 'karpenter' found. Cleaning up Karpenter resources..."
  # Attempt to uninstall via Helm if installed as a release.
  helm uninstall karpenter -n karpenter 2>/dev/null || echo "Karpenter not installed via Helm, or already removed."
  # Delete the Karpenter namespace.
  kubectl delete namespace karpenter --ignore-not-found
else
  echo "Karpenter namespace not found. Skipping Karpenter cleanup."
fi

echo "Searching for Ingress resources with the AWS ALB finalizer..."
INGRESSES=$(kubectl get ingress --all-namespaces -o json | \
  jq -r '.items[] | select(.metadata.finalizers != null and (.metadata.finalizers[] | contains("ingress.k8s.aws/resources"))) | "\(.metadata.namespace) \(.metadata.name)"')

if [ -n "$INGRESSES" ]; then
  echo "Found the following Ingress resources with finalizers:"
  echo "$INGRESSES"
  while IFS= read -r line; do
    ns=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    echo "Removing finalizers from Ingress $name in namespace $ns..."
    kubectl patch ingress "$name" -n "$ns" --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
  done <<< "$INGRESSES"
else
  echo "No Ingress resources with the AWS ALB finalizer were found."
fi

echo "Waiting 120 seconds for deletions to propagate..."
sleep 120

echo "Current PVC status in the cluster:"
kubectl get pvc --all-namespaces || true

echo "===== RESOURCE CLEANUP COMPLETE ====="
echo ""

# Phase 2: Infrastructure Destruction with Terraform
echo "Executing 'terraform destroy' to tear down the cluster infrastructure..."
terraform destroy -auto-approve

echo "Script completed."