#!/bin/bash
set -euo pipefail

# Check that jq, kubectl, helm, and terraform are installed.
for cmd in jq kubectl helm terraform; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: Command '$cmd' is not installed. Please install it to continue."
    exit 1
  fi
done

# Get the current context
current_context=$(kubectl config current-context)

# Extract the cluster identifier from the current context
cluster_identifier=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$current_context\")].context.cluster}")

# If the cluster identifier is an ARN, extract the actual cluster name
CLUSTER_NAME=$(echo "$cluster_identifier" | awk -F'/' '{print $NF}')

echo "Active cluster: $CLUSTER_NAME"

echo "===== STARTING CLUSTER RESOURCE CLEANUP ====="

# --- STEP 1: CLEANUP OF KUBERNETES RESOURCES ---

# 1.1 Uninstall the Prometheus Helm release (if exists) in the 'monitoring' namespace.
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
  echo "Found the following PVCs with finalizers:"
  echo "$stuck_pvcs"
  while IFS= read -r line; do
    ns=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    echo "Removing finalizers from PVC $name in namespace $ns..."
    kubectl patch pvc "$name" -n "$ns" --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
  done <<< "$stuck_pvcs"
else
  echo "No PVCs with pending finalizers found."
fi

# 1.4 Remove finalizers from any Ingress that have the AWS ALB finalizer.
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
  echo "No Ingress resources with the AWS ALB finalizer found."
fi

# 1.5 Optional: Clean up Karpenter resources if installed.
echo "Checking for Karpenter installation..."
if kubectl get ns karpenter &> /dev/null; then
  echo "Namespace 'karpenter' found. Cleaning up Karpenter resources..."
  helm uninstall karpenter -n karpenter 2>/dev/null || echo "Karpenter not installed via Helm, or already removed."
  kubectl delete namespace karpenter --ignore-not-found
else
  echo "Karpenter namespace not found. Skipping Karpenter cleanup."
fi

echo "Waiting 30 seconds for Kubernetes resource deletions to propagate..."
sleep 30

echo "Current PVC status in the cluster:"
kubectl get pvc --all-namespaces || true

# --- STEP 2: CLEANUP OF AWS LOAD BALANCERS ---

echo "Searching for AWS Load Balancers associated with cluster '${CLUSTER_NAME}'..."
# List all ALB ARNs in the region.
ALB_ARNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerArn" --output text)

if [ -n "$ALB_ARNS" ]; then
  for alb in $ALB_ARNS; do
    # Check if the ALB has the tag "kubernetes.io/cluster/<cluster-name>" with value "owned".
    TAG_VALUE=$(aws elbv2 describe-tags --resource-arns $alb --query "TagDescriptions[0].Tags[?Key=='kubernetes.io/cluster/${CLUSTER_NAME}'].Value" --output text)
    if [ "$TAG_VALUE" = "owned" ]; then
      echo "Deleting Load Balancer: $alb (tagged as owned by cluster ${CLUSTER_NAME})..."
      aws elbv2 delete-load-balancer --load-balancer-arn $alb
    fi
  done
else
  echo "No Load Balancers found."
fi

# --- STEP 3: INFRASTRUCTURE DESTRUCTION WITH TERRAFORM ---

echo "Executing 'terraform destroy' to tear down the cluster infrastructure..."
terraform destroy -auto-approve

echo "Script completed."