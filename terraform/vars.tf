######################################################### VARS #########################################################
# INFO: https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables

# Suscripción de Azure
variable "subscription_id" {
  type = string
}

# Declaramos el grupo de recursos
variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
  default     = "rg-resources"
}

# Declaramos una variable para el etiquetado
variable "common_tags" {
  type = map(string)
  default = {
    environment = "casopractico2"
  }
}

# INFO: https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md
# Lista de regiones permitidas de Azure con tu suscripción:
# az account list-locations --query "[?metadata.regionCategory=='Recommended'].[name, displayName]" -o table
# Declaramos la región de la infraestructura de azure
variable "location_name" {
  description = "Azure region where the infrastructure is deployed"
  type        = string
  default     = "spaincentral"
  #default     = "switzerlandnorth"
}

######################################################## VM VARS #######################################################

# INFO: https://docs.microsoft.com/es-es/azure/cloud-services/cloud-services-sizes-specs
# Declaramos la vm master y establecemos sus características (Standard_D2s_v3)
variable "cluster_aks" {
  description = "VM size for AKS default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "dns_prefix" {
  description = "DNS prefix specified when creating the managed cluster"
  type        = string
  default     = "aks-practica-2"
}

variable "aks_node_pool" {
  description = "Name of the default Kubernetes Node Pool"
  type        = string
  default     = "nodepool"
}

variable "aks_network_plugin" {
  description = "Network plugin to use for AKS"
  type        = string
  default     = "kubenet"

  validation {
    condition     = contains(["kubenet", "azure"], var.aks_network_plugin)
    error_message = "aks_network_plugin must be 'kubenet' or 'azure'."
  }
}

variable "aks_lb_sku" {
  description = "Load Balancer SKU for AKS"
  type        = string
  default     = "standard"

  validation {
    condition     = var.aks_lb_sku == "standard"
    error_message = "AKS solo soporta Load Balancer 'standard'."
  }
}

variable "aks_identity" {
  description = "Managed Identity type for AKS"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.aks_identity)
    error_message = "aks_identity must be 'SystemAssigned' or 'UserAssigned'."
  }
}

# Declaramos la vm webservice y establecemos sus características (standard_b2ls_v2)
variable "webservice_vm" {
  description = "VM size for Webservice"
  type        = string
  default     = "standard_b2ls_v2"
}

variable "os_disk_specs" {
  description = "Virtual Machine OS disk specs"

  type = object({
    caching              = string
    storage_account_type = string
  })

  default = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# Comando para establecer los valores requeridos en la creación de la máquina virtual:
# az vm image list --publisher Canonical --offer ubuntu-24_04-lts --all --output table
# Comando para establecer los valores requeridos en el plan para este tipo de VM:
# az vm image show --location spaincentral --urn Canonical:ubuntu-24_04-lts:server:latest
variable "os_image_specs" {
  description = "Virtual Machine Image Specs"

  type = object({
    name      = string
    product   = string
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

  default = {
    name      = "ubuntu2404"
    product   = "ubuntu-24_04-lts"
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# Declaramos el SKU del container registry ACR
variable "acr_sku" {
  description = "Azure Container Registry SKU"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "acr_sku must be Basic, Standard or Premium."
  }
}

#################################################### CONNECTION VARS ###################################################

# Declaramos el usuario ssh para conectarse
variable "ssh_user" {
  description = "SSH connection user"
  type        = string
  default     = "azureuser"
}

##################################################### NETWORK VARS #####################################################

# Declaramos la red (vnet)
variable "network_name" {
  description = "Virtual Network name"
  type        = string
  default     = "vnet"
}

# Declaramos la subred (subnet)
variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "subnet"
}

# Declaramos la IP pública de la VM webservice
variable "webservice_pip_name" {
  description = "Public IP name for webservice"
  type        = string
  default     = "webservice-pip"
}

# Declaramos la interfaz de red de la VM webservice
variable "webservice_vnic_name" {
  description = "Network interface name for webservice"
  type        = string
  default     = "webservice-vnic"
}

#################################################### SECURITY VARS #####################################################

# Declaramos la security_rule_conf para ssh/http
variable "webservice_security_rule_conf" {
  description = "Security rules for webservice NSG"

  type = map(object({
    name                   = string
    priority               = number
    destination_port_range = string
  }))

  default = {
    ssh = {
      name                   = "ssh"
      priority               = 1002
      destination_port_range = "22"
    },
    http = {
      name                   = "http"
      priority               = 1003
      destination_port_range = "8080"
    }
  }
}

# Declaramos el role_definition_name
variable "role_definition" {
  description = "Role definition name for ACR access"
  type        = string
  default     = "AcrPull"
}

################################################### LOCALFILES VARS ####################################################

# Declaramos la ruta del fichero de variables para ansible
variable "ansible_vars_filename" {
  description = "Path to ansible vars file"
  type        = string
  default     = "../ansible/group_vars/all.yml"
}

# Declaramos la ruta del fichero kubeconfig
variable "tf_ansible_kube_config_filename" {
  description = "Path to exported kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}
