resource "local_file" "ngnix_deployment" {
  content  = data.template_file.ngnix_deployment.rendered
  filename = "${path.module}/ngnix.yaml"
}

resource "local_file" "service_deployment" {
  content  = data.template_file.service_deployment.rendered
  filename = "${path.module}/service.yaml"
}

resource "null_resource" "deploy_oke_ngnix" {
  depends_on = [
  oci_containerengine_cluster.FoggyKitchenOKECluster, 
  oci_containerengine_node_pool.FoggyKitchenOKENodePool, 
  local_file.ngnix_deployment,
  local_file.service_deployment]

  provisioner "local-exec" {
    command = "oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.FoggyKitchenOKECluster.id}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.ngnix_deployment.filename}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.service_deployment.filename}"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "local-exec" {
    command = "kubectl get pods"
  }

  provisioner "local-exec" {
    command = "kubectl get services"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete service lb-service"
  }

}