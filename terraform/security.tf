############################################### SECURITY GROUPS RESOURCES ##############################################

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
# Definimos el grupo de recursos donde estarán asociados todos recursos que necesitemos crear
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_name
  tags     = var.common_tags
}

# Definimos los grupos de seguridad para limitar el acceso y los puertos necesarios a utilizar

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
# Definimos el grupo de seguridad para nuestro webservice con dos reglas:
#   + ssh
#   + http
# para poder acceder a la aplicación desde el exterior a Azure
resource "azurerm_network_security_group" "webservice_nsg" {
  name                = "webservice-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.common_tags
  dynamic "security_rule" {
    for_each = var.webservice_security_rule_conf
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association
# Asociamos el grupo de seguridad a cada interfaz de red de cada máquina
resource "azurerm_network_interface_security_group_association" "webservice_nisga" {
  network_interface_id      = azurerm_network_interface.webservice_vnic.id
  network_security_group_id = azurerm_network_security_group.webservice_nsg.id
}

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
# Asigna una entidad de seguridad determinada (usuario o grupo) a un rol determinado
resource "azurerm_role_assignment" "ra" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = var.role_definition
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
