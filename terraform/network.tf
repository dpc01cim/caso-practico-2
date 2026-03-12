################################################## NETWORK RESOURCES ##################################################

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
# Definimos la interfaz virtual de red y la asociamos al resource_group
resource "azurerm_virtual_network" "vnet" {
  name                = var.network_name
  address_space       = ["10.0.40.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.common_tags
}

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
# Definimos la subnet con el rango de IPs que tendrá nuestro cluster AKS y nuestro WS
# asociando la virtual_network creada y el resource_group
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.40.0/27"]

  delegation {
    name = "aks-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
# Definimos la IP pública de la VM del webservice y le asociamos el resource_group
resource "azurerm_public_ip" "webservice_pip" {
  name                = var.webservice_pip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

# INFO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
# Definimos la interfaz y la configuración de red del webservice y le
# asociamos la subnet configurando una ip privada y otra pública
resource "azurerm_network_interface" "webservice_vnic" {
  name                = var.webservice_vnic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.common_tags

  ip_configuration {
    name                          = var.subnet_name
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.40.18"
    public_ip_address_id          = azurerm_public_ip.webservice_pip.id
  }
}
