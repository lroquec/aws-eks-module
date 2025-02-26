resource "kubectl_manifest" "update_gp2_annotation" {
  yaml_body = <<-YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
  name: gp2
YAML

  server_side_apply = true
  force_conflicts   = true

  depends_on = [module.eks, time_sleep.wait_for_cluster]
}

resource "kubectl_manifest" "gp2_immediate" {
  yaml_body = <<-YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: gp2-immediate
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  type: gp2
  fsType: ext4
YAML

  depends_on = [kubectl_manifest.update_gp2_annotation]
}