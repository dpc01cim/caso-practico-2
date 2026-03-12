# Terraform

## Introducción a Terraform en Azure

Hashicorp Terraform es una herramienta iaC de código abierto (infraestructura como código) para aprovisionar y 
administrar la infraestructura en la nube. Codifica la infraestructura en los archivos de configuración que describen 
el estado deseado para la topología. Terraform permite la administración de cualquier infraestructura (como nubes 
públicas, nubes privadas y servicios SaaS) mediante proveedores de Terraform.

## Utilización de Terraform en Azure

### Requisitos

* Una suscripción válida en Azure.
* Una maquina con sistema operativo Linux (Ubuntu).
* Terraform versión **0.14.9** o superior.
* Azure CLI instalado.
* Generar clave ssh: `ssh-keygen -t rsa -b 4096`

### Instalación Terraform

El proceso de instalación de terraform en el SO Linux está documentado en:

- https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
- https://www.hashicorp.com/official-packaging-guide

Paquetería necesaria: `sudo apt-get update && sudo apt-get install -y gnupg software-properties-common`

GPG key: `wget -O- https://apt.releases.hashicorp.com/gpg | \
          gpg --dearmor | \
          sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null`

Repositorio oficial de HashiCorp: `echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
                                   https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | \
                                   sudo tee /etc/apt/sources.list.d/hashicorp.list`

Actualizar la paquetería: `sudo apt update`

Instalar terraform: `sudo apt install terraform`

### Instalación Azure CLI

Para poder utilizar terraform en azure es necesario instalar Azure CLI:

- https://learn.microsoft.com/es-es/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt
- https://github.com/Azure/azure-cli/blob/dev/README.md
- https://learn.microsoft.com/es-es/cli/azure/reference-index?view=azure-cli-latest#az-login

`curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`

### Conexión con Azure
Una vez instalado el Azure CLI, para realizar la conexión, desde consola ejecutamos:

`az login --use-device-code`

URL de la conexión: `https://microsoft.com/devicelogin` + CÓDIGO

### Uso de Terraform

* Inicializar terraform: `terraform init`
* Crear el plan de la infraestructura: `terraform plan`
* Crear la infraestructura en Azure: `terraform apply --auto-approve`
* Eliminar toda la infraestructura creada en Azure: `terraform destroy --auto-approve`

### Acceso a las máquinas de Azure

Para poder acceder a los recursos generados por ssh: `ssh USER@IP -i .ssh/id_rsa.pub`

#### Uso de imágenes

Documentación sobre el uso de las imágenes en Azure CLI:

- https://learn.microsoft.com/es-es/cli/azure/vm/image?view=azure-cli-latest
- https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
- https://learn.microsoft.com/es-es/cli/azure/vm/image?source=recommendations&view=azure-cli-latest
