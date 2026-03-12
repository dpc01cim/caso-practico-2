#!/bin/bash

# Es necesario tener instalado el Azure CLI y estar conectado a una cuenta de Azure para ejecutar este script.

# Inicializar terraform
terraform init

# Crear el plan de la infraestructura
terraform plan

# Crear la infraestructura en Azure
terraform apply --auto-approve

# Exportar la clave privada de la vm en Azure
terraform output -raw ssh_private_key > ~/.ssh/private_key.pem
chmod 600 ~/.ssh/private_key.pem
