###################################################### RESOURCES #######################################################

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
# Definimos el clúster de kubernetes AKS con todos los recursos necesarios
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  sku_tier            = "Standard"
  tags                = var.common_tags

  default_node_pool {
    name       = var.aks_node_pool
    node_count = 1
    vm_size    = var.cluster_aks
    type       = "VirtualMachineScaleSets"
  }

  identity {
    type = var.aks_identity
  }

  linux_profile {
    admin_username = var.ssh_user

    ssh_key {
      key_data = tls_private_key.ssh_key.public_key_openssh
    }
  }

  network_profile {
    network_plugin    = var.aks_network_plugin
    load_balancer_sku = var.aks_lb_sku
  }
}

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
# Definimos la máquina virtual webservice con todos los recursos necesarios
resource "azurerm_linux_virtual_machine" "webservice" {
  name                  = "webservice"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.webservice_vm
  admin_username        = var.ssh_user
  tags                  = var.common_tags
  network_interface_ids = [
    azurerm_network_interface.webservice_vnic.id
  ]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = var.os_disk_specs.caching
    storage_account_type = var.os_disk_specs.storage_account_type
  }

  source_image_reference {
    publisher = var.os_image_specs.publisher
    offer     = var.os_image_specs.offer
    sku       = var.os_image_specs.sku
    version   = var.os_image_specs.version
  }
}

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry
# Definimos el registry donde almacenar las imágenes con todos los recursos necesarios
resource "azurerm_container_registry" "acr" {
  name                = "dpccontainerregistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = true
  tags                = var.common_tags
}

# INFO: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
# Exportar variables de terraform necesarias para ansible
resource "local_file" "tf_ansible_vars" {
  filename = "${path.module}/${var.ansible_vars_filename}"

  content  = <<-DOC
    # Archivo generado automáticamente por Terraform
    acr_url: "${azurerm_container_registry.acr.login_server}"
    acr_password: "${azurerm_container_registry.acr.admin_password}"
    acr_username: "${azurerm_container_registry.acr.admin_username}"

    webservice_pip: "${azurerm_linux_virtual_machine.webservice.public_ip_address}"

    # Ruta absoluta al kubeconfig generado
    kubeconfig_path: "${var.tf_ansible_kube_config_filename}"
    DOC
}

# Inventario de ansible para el entorno de producción
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    webservice_pip = azurerm_linux_virtual_machine.webservice.public_ip_address
    private_key_path = "~/.ssh/private_key.pem"
  })
  filename = "${path.module}/../ansible/environments/production/inventory.azure"
}

# Crear el fichero kubeconfig para acceder al cluster de Kubernetes
resource "local_file" "kubeconfig" {
  content         = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename        = "${pathexpand(var.tf_ansible_kube_config_filename)}"
  file_permission = "0600"
}
