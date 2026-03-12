################################################### OUTPUT VARS #######################################################

# Declaramos como variable de salida el grupo de recursos
output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

# Variables de salida del AKS
output "aks_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_host" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive = true
}

output "aks_username" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].username
  sensitive = true
}

output "aks_password" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].password
  sensitive = true
}

output "aks_ca_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

# Variables de salida del webservice
output "webservice_id" {
  value = azurerm_linux_virtual_machine.webservice.id
}

output "webservice_pip" {
  value = azurerm_linux_virtual_machine.webservice.public_ip_address
}

output "ssh_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

# Variables de salida del ACR
output "acr_url" {
  description = "La URL del servidor de login del ACR"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_username" {
  description = "El nombre de usuario administrador del ACR"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_password" {
  value     = azurerm_container_registry.acr.admin_password
  sensitive = true
}
