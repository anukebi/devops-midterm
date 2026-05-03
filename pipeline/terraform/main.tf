provider "local" {}

variable "deployment_directory" {
  type = string
}

locals {
  deployment_directory = var.deployment_directory
}

resource "null_resource" "create_deployment_directories" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${local.deployment_directory}/deployment-current
      mkdir -p ${local.deployment_directory}/deployment-blue
      mkdir -p ${local.deployment_directory}/deployment-green
      find ${local.deployment_directory} -type d -exec bash -c 'mv "$0" "$(echo "$0" | tr -d "\r")"' {} \;
    EOT
  }
}
