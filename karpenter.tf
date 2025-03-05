# Karpenter IAM Role
resource "aws_iam_role" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0
  name  = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0
  name  = "karpenter-policy"
  role  = aws_iam_role.karpenter_controller[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "iam:CreateServiceLinkedRole",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeInstanceStatus",
          "eks:UpdateNodegroupConfig",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      }
    ]
  })
}

data "aws_iam_role" "nodegroup_role" {
  name = module.eks.eks_managed_node_groups["main"].iam_role_name
}


# Deploy Karpenter 
resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller[0].arn
  }
  set {
    name  = "crds.install"
    value = "true"
  }

  set {
    name  = "controller.topologySpreadConstraints[0].whenUnsatisfiable"
    value = "ScheduleAnyway"
  }

  set {
    name  = "controller.topology.enabled"
    value = "false"
  }

  set {
    name  = "replicas"
    value = "1"
  }

  depends_on = [time_sleep.wait_for_cluster, module.eks]
}

# Wait till CRDs are installed
resource "time_sleep" "wait_for_crds" {
  count           = var.enable_karpenter ? 1 : 0
  depends_on      = [helm_release.karpenter]
  create_duration = "60s"
}

# Get latest AL2 EKS-optimized AMI
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
}

# Create Karpenter NodeTemplate
resource "kubectl_manifest" "karpenter_node_template" {
  count      = var.enable_karpenter ? 1 : 0
  depends_on = [time_sleep.wait_for_crds]
  yaml_body  = <<-YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023 # Dropped support for AL2
  role: "${data.aws_iam_role.nodegroup_role.name}"
  subnetSelectorTerms:
    - tags:
        kubernetes.io/role: private
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${var.cluster_name}
  amiSelectorTerms:
    - id: "${data.aws_ssm_parameter.eks_ami.value}"
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 30Gi
        volumeType: gp2

  tags:
    Environment: ${var.environment}
    ManagedBy: karpenter
    Purpose: testing
YAML
}

# Create Karpenter Provisioner
resource "kubectl_manifest" "karpenter_provisioner" {
  count      = var.enable_karpenter ? 1 : 0
  depends_on = [time_sleep.wait_for_crds, kubectl_manifest.karpenter_node_template]
  yaml_body  = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t3.medium", "t3.xlarge", "m5.xlarge"]
      nodeClassRef:
        name: default
        group: karpenter.k8s.aws
        kind: EC2NodeClass
  limits:
    cpu: 50
    memory: 50Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
    expireAfter: 720h
YAML
}
