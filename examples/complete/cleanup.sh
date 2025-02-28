#!/bin/bash
# Enhanced cleanup script for EKS resources
# This script ensures proper cleanup of all resources before running terraform destroy

# Don't set -e because we want to continue even if some commands fail
# We'll handle errors appropriately ourselves

# Colores para mejor legibilidad
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Script de limpieza EKS - Elimina recursos para permitir terraform destroy sin problemas ===${NC}"

# Try to get the cluster name from the current context
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
if [[ $CURRENT_CONTEXT == *"/"* ]]; then
  CLUSTER_NAME=$(echo $CURRENT_CONTEXT | cut -d'/' -f2)
else
  # If we can't get it from the context, try to get it from kubectl config view
  CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' 2>/dev/null || echo "")
  
  # If still empty, ask the user
  if [ -z "$CLUSTER_NAME" ]; then
    echo "Could not automatically determine cluster name."
    read -p "Please enter your EKS cluster name: " CLUSTER_NAME
  fi
fi
echo "Starting cleanup for cluster: $CLUSTER_NAME"

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required tools
for cmd in kubectl aws jq; do
  if ! command_exists $cmd; then
    echo "Error: $cmd is required but not installed. Please install it and try again."
    exit 1
  fi
done

# 1. Scale down all deployments to avoid issues during teardown
echo "Scaling down all deployments in all namespaces..."
kubectl get ns --no-headers | awk '{print $1}' | xargs -I{} kubectl scale deployment --all --replicas=0 -n {} || true
echo "Waiting for pods to start terminating..."
sleep 10

# 2. Find and delete any ingress resources first (to trigger ALB deletion)
# Function to force delete kubernetes resources by removing finalizers
force_delete_resource() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  
  echo "Forzando eliminación de $resource_type/$resource_name en namespace $namespace"
  kubectl get $resource_type $resource_name -n $namespace -o json | jq '.metadata.finalizers = null' | kubectl replace --raw "/api/$4/$resource_name" -f - -n $namespace
}

echo "Finding and deleting all ingress resources..."
for NS in $(kubectl get ns --no-headers | awk '{print $1}'); do
  # Get all ingress resources in this namespace and delete them
  INGRESSES=$(kubectl get ingress -n $NS -o name 2>/dev/null | cut -d'/' -f2 || true)
  if [ -n "$INGRESSES" ]; then
    echo "Deleting ingresses in namespace $NS"
    for ING in $INGRESSES; do
      echo "  Deleting ingress $ING"
      # Try normal delete first
      kubectl delete ingress $ING -n $NS --wait=false
      
      # Check if it's still there after 5 seconds
      sleep 5
      if kubectl get ingress $ING -n $NS &>/dev/null; then
        echo "  Ingress $ING aún existe, intentando eliminación forzada..."
        # Force delete by removing finalizers
        kubectl patch ingress $ING -n $NS -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        # If patch fails, try the more aggressive approach
        RESOURCE_VERSION=$(kubectl get ingress $ING -n $NS -o jsonpath='{.metadata.resourceVersion}')
        kubectl proxy &
        PROXY_PID=$!
        sleep 2
        curl -k -H "Content-Type: application/json" -X PUT --data-binary @<(kubectl get ingress $ING -n $NS -o json | jq '.metadata.finalizers = []') http://127.0.0.1:8001/apis/networking.k8s.io/v1/namespaces/$NS/ingresses/$ING?resourceVersion=$RESOURCE_VERSION || true
        kill $PROXY_PID
      fi
    done
  fi
done
sleep 20

# 3. Find and remove all AWS Load Balancers created by the Kubernetes cluster
echo "Checking for any AWS Load Balancers created by the cluster..."
LB_ARNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerArn" --output text)

# Filter manually since the complex query is causing issues
FILTERED_LB_ARNS=""
for LB_ARN in $LB_ARNS; do
  # Get tags for this load balancer
  TAGS=$(aws elbv2 describe-tags --resource-arns $LB_ARN --query "TagDescriptions[0].Tags" --output json)
  
  # Check if this load balancer is associated with our cluster
  if echo "$TAGS" | jq -e ".[] | select((.Key == \"kubernetes.io/cluster/$CLUSTER_NAME\" and .Value == \"owned\") or (.Key == \"elbv2.k8s.aws/cluster\" and .Value == \"true\"))" > /dev/null; then
    FILTERED_LB_ARNS="$FILTERED_LB_ARNS $LB_ARN"
  fi
done

LB_ARNS=$FILTERED_LB_ARNS

if [ -n "$LB_ARNS" ]; then
  echo "Found load balancers to remove:"
  for LB_ARN in $LB_ARNS; do
    LB_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns $LB_ARN --query "LoadBalancers[0].LoadBalancerName" --output text)
    echo "  - Deleting load balancer: $LB_NAME"
    aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
    echo "    Load balancer deletion initiated"
  done
  echo "Waiting for load balancers to be deleted..."
  sleep 30
else
  echo "No load balancers found associated with the cluster"
fi

# 4. Find and remove any target groups created by the cluster
echo "Checking for any orphaned target groups..."
# Get all target groups first
ALL_TARGET_GROUPS=$(aws elbv2 describe-target-groups --query "TargetGroups[].TargetGroupArn" --output text)

# Filter target groups related to our cluster
TARGET_GROUPS=""
for TG_ARN in $ALL_TARGET_GROUPS; do
  # Get tags for this target group
  TG_TAGS=$(aws elbv2 describe-tags --resource-arns $TG_ARN --query "TagDescriptions[0].Tags" --output json 2>/dev/null || echo "[]")
  
  # Check if this target group is associated with our cluster
  if echo "$TG_TAGS" | jq -e ".[] | select((.Key == \"kubernetes.io/cluster/$CLUSTER_NAME\") or (.Key == \"elbv2.k8s.aws/cluster\"))" > /dev/null 2>&1; then
    TARGET_GROUPS="$TARGET_GROUPS $TG_ARN"
  fi
done

if [ -n "$TARGET_GROUPS" ]; then
  echo "Found target groups to remove:"
  for TG_ARN in $TARGET_GROUPS; do
    TG_NAME=$(aws elbv2 describe-target-groups --target-group-arns $TG_ARN --query "TargetGroups[0].TargetGroupName" --output text)
    echo "  - Deleting target group: $TG_NAME"
    aws elbv2 delete-target-group --target-group-arn $TG_ARN
    echo "    Target group deleted"
  done
else
  echo "No target groups found associated with the cluster"
fi

# 5. If Karpenter is enabled, clean up Karpenter resources
if kubectl get deployment -n karpenter karpenter 2>/dev/null; then
  echo "Karpenter detected, cleaning up Karpenter resources..."
  echo "Deleting all Karpenter NodePools..."
  kubectl delete nodepools --all 2>/dev/null || true
  
  echo "Patching finalizers on any stuck nodepools..."
  for NODEPOOL in $(kubectl get nodepools -o name 2>/dev/null | cut -d'/' -f2); do
    kubectl patch nodepool $NODEPOOL -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
    
    # If still stuck, try more aggressive approach
    if kubectl get nodepool $NODEPOOL &>/dev/null; then
      echo "  NodePool $NODEPOOL aún bloqueado, usando eliminación forzada..."
      RESOURCE_VERSION=$(kubectl get nodepool $NODEPOOL -o jsonpath='{.metadata.resourceVersion}')
      kubectl proxy &
      PROXY_PID=$!
      sleep 2
      curl -k -H "Content-Type: application/json" -X PUT --data-binary @<(kubectl get nodepool $NODEPOOL -o json | jq '.metadata.finalizers = []') http://127.0.0.1:8001/apis/karpenter.sh/v1/nodepools/$NODEPOOL?resourceVersion=$RESOURCE_VERSION || true
      kill $PROXY_PID
    fi
  done
  
  echo "Waiting for nodes to terminate..."
  sleep 30
fi

# 6. Check and remove any persistent volumes or claims
echo "Removing any persistent volumes and claims..."
kubectl delete pvc --all --all-namespaces --wait=false || true
echo "Waiting for PVCs to be deleted..."
sleep 10
kubectl delete pv --all --wait=false || true

# 7. Check for any stuck namespaces and fix them
echo "Checking for stuck namespaces..."
for NS in $(kubectl get ns --no-headers | grep Terminating 2>/dev/null | awk '{print $1}'); do
  echo "Found stuck namespace: $NS, removing finalizers..."
  kubectl get namespace $NS -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f -
done

# 8. Final cleanup of any remaining resources
echo "Removing any remaining custom resources that might block deletion..."
kubectl delete --all deployments,services,endpoints --all-namespaces --wait=false || true
# Delete ingresses separately as they need special handling
for NS in $(kubectl get ns --no-headers | awk '{print $1}'); do
  kubectl delete ingress --all -n $NS --wait=false 2>/dev/null || true
done
# Continue with other resources
kubectl delete --all jobs,cronjobs,daemonsets,statefulsets --all-namespaces --wait=false || true
# Be careful with deleting configmaps and secrets as they might be needed by the system
echo "Note: ConfigMaps and Secrets are not deleted to avoid breaking system components"

# Check for any remaining load balancers
echo "Performing final check for remaining AWS load balancers..."
REMAINING_LBS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerArn" --output text)
if [ -n "$REMAINING_LBS" ]; then
  echo "There are still some load balancers in your account. You may need to check them manually."
  echo "Consider checking the AWS Console or running: aws elbv2 describe-load-balancers"
else
  echo "No load balancers found in your account."
fi

echo "Cleanup completed. Now you can safely run: terraform destroy"
echo "If terraform destroy fails due to resources still being deleted, wait a few minutes and try again."

echo "Proceeding with terraform destroy..."
terraform destroy -auto-approve