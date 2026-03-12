# Despliegue de AKS + WebService + ACR (Caso Práctico II)

Playbook de Ansible para desplegar una infraestructura completa en Azure que incluye un Azure Container Registry (ACR), un clúster AKS con SonarQube, y una máquina virtual con un servidor web containerizado.

## Estructura del Proyecto

```
.
├── ansible.cfg                      # Configuración de Ansible
├── requirements.yml                  # Dependencias de colecciones Ansible
├── deploy.sh                         # Script de despliegue automatizado
├── playbook.yml                       # Playbook principal de despliegue
├── environments/                      # Configuraciones por entorno
│   └── production/                     # Entorno de producción
│       └── inventory.azure               # Inventario de Azure
├── group_vars/                        # Variables globales
│   └── all.yml                           # Generado por Terraform
├── roles/                             # Roles de Ansible
│   ├── acr/                             # Gestión de Azure Container Registry
│   ├── sonarqube/                        # Despliegue de SonarQube en AKS
│   └── vm/                               # Despliegue de servidor web containerizado
└── README.md                          # Este archivo
```

## Archivos de Configuración

### `ansible.cfg`
```ini
[defaults]
collections_paths = ~/.ansible/collections:/usr/share/ansible/collections
host_key_checking = False
```

### `requirements.yml`
```yaml
collections:
  - name: community.crypto           # Módulos para certificados SSL/TLS
  - name: containers.podman           # Módulos para gestionar Podman
  - name: community.postgresql        # Módulos para PostgreSQL
  - name: community.kubernetes        # Módulos para Kubernetes
```

### `deploy.sh`
```bash
#!/bin/bash

# Install galaxy collections for ansible.
ansible-galaxy collection install -r requirements.yml

# Playbook for install the Webserver, SonarQube in Azure AKS and Postgres database.
ansible-playbook -i environments/production/inventory.azure playbook.yml --ask-become-pass --ask-vault-pass -v -K
```

**Explicación del script:**
- `--ask-become-pass`: Solicita contraseña para privilegios sudo
- `--ask-vault-pass`: Solicita contraseña para desencriptar Ansible Vault
- `-v`: Modo verbose para más detalles
- `-K`: Solicita contraseña de sudo (equivalente a --ask-become-pass)

## Integración con Terraform

Terraform genera automáticamente el archivo `group_vars/all.yml` con las siguientes variables:

```yaml
# Archivo generado automáticamente por Terraform
acr_url: "nombreacr.azurecr.io"
acr_password: "contraseña_generada"
acr_username: "nombre_usuario"
webservice_pip: "XX.XXX.XXX.XX"
```

Estas variables son fundamentales para la comunicación entre los diferentes componentes del proyecto.

## Playbook Principal: `playbook.yml`

El playbook orquesta todo el despliegue y está estructurado para ejecutar los roles en el orden correcto:

```yaml
---
- hosts: localhost
  roles:
    - role: acr
      tags: ['registry']
  
- hosts: localhost
  roles:
    - role: aks
      tags: ['k8s']

- hosts: vm
  roles:
    - role: vm
      tags: ['webservice']
```

## Roles

### 1. Rol ACR (`roles/acr/`)

Gestiona la autenticación y subida de imágenes al Azure Container Registry.

**Variables principales:**
- `acr_url`: URL del registro de contenedores
- `acr_username`: Usuario de autenticación
- `acr_password`: Contraseña de autenticación
- `acr_images`: Lista de imágenes a procesar (src/dest)
- `tag_image`: Tag común para todas las imágenes (`casopractico2`)

**Imágenes gestionadas:**
```yaml
acr_images:
  - { src: "docker.io/library/httpd:alpine", dest: "library/httpd" }
  - { src: "docker.io/library/sonarqube:community", dest: "library/sonarqube" }
  - { src: "docker.io/library/postgres:17.9-alpine", dest: "library/postgres" }
```

**Tags:**
- `setup_local`: Instalación de Podman y herramientas
- `acr_push`: Login, pull, tag y push de imágenes
- `clean_images`: Limpieza de imágenes locales

### 2. Rol SonarQube (`roles/sonarqube/`)

Despliega SonarQube en un clúster AKS con PostgreSQL como base de datos.

**Variables principales:**
- `k8s_namespace`: Namespace en Kubernetes (`sonarqube`)
- `k8s_templates`: Lista de plantillas de Kubernetes
- `deployment`: Configuración del Deployment (recursos, puertos)
- `svc`: Configuración del Service (tipo LoadBalancer)
- `pvc`: Configuración de volúmenes persistentes

**Objetos Kubernetes desplegados:**
- `acr-secret.yml`: Secret para autenticación con ACR
- `sonar-data.yml`: PVC para datos de SonarQube
- `sonar-extensions.yml`: PVC para extensiones
- `postgres-secret.yml`: Credenciales de PostgreSQL
- `postgres-pvc.yml`: Volumen persistente para PostgreSQL
- `postgres-service.yml`: Service de PostgreSQL
- `postgres-deployment.yml`: Deployment de PostgreSQL
- `sonar-service.yml`: Service de SonarQube (LoadBalancer)
- `sonar-deployment.yml`: Deployment principal de SonarQube

**Secretos (encriptados con Ansible Vault):**
```yaml
# vault.yml (encriptado)
db_password: "******"      # Password PostgreSQL
```

### 3. Rol VM/WebService (`roles/vm/`)

Configura una máquina virtual con un servidor web containerizado usando Podman.

**Variables principales:**
- `username`/`password`: Credenciales de autenticación básica
- `webserver_path`: Ruta de trabajo (`/opt/webserver`)
- `server_hostname`: Hostname para certificados TLS
- `container_templates`: Plantillas de configuración

**Características del servidor web:**
- Imagen base: `httpd:alpine` desde ACR
- Autenticación básica (archivo `.creds`)
- TLS/SSL con certificado autofirmado
- Puerto expuesto: `8080` (https)
- Servicio systemd para auto-arranque

**Archivos generados:**
- Clave privada RSA (`*.key`)
- CSR (Certificate Signing Request)
- Certificado autofirmado (`*.crt`)
- Archivo de credenciales (`.creds`)
- Configuración de Apache (`httpd.conf`)
- Página web personalizada (`index.html`)

## Plantillas (Templates)

### Rol SonarQube (`roles/sonarqube/templates/`)
- `acr-secret.yml.j2`
- `sonar-data.yml.j2`
- `sonar-extensions.yml.j2`
- `postgres-secret.yml.j2`
- `postgres-pvc.yml.j2`
- `postgres-service.yml.j2`
- `postgres-deployment.yml.j2`
- `sonar-service.yml.j2`
- `sonar-deployment.yml.j2`

### Rol VM (`roles/vm/templates/`)
- `.htaccess.j2`: Configuración de autenticación básica
- `Containerfile.j2`: Instrucciones para construir la imagen
- `httpd.conf.j2`: Configuración del servidor Apache
- `index.html.j2`: Página web personalizada

## Flujo de Despliegue Completo

### 1. Preparación del Entorno
```bash
# Dar permisos de ejecución al script
chmod +x deploy.sh

# Ejecutar despliegue completo
./deploy.sh
```

### 2. Lo que hace `deploy.sh`:
```bash
# Paso 1: Instalar colecciones de Ansible Galaxy
ansible-galaxy collection install -r requirements.yml

# Paso 2: Ejecutar playbook principal
ansible-playbook -i environments/production/inventory.azure playbook.yml --ask-become-pass --ask-vault-pass -v -K
```

### 3. Proceso Interno del Playbook

**Fase 1 - ACR (localhost):**
- Instalación de Podman
- Login en ACR
- Pull de imágenes de Docker Hub
- Tag para ACR
- Push al registro
- Limpieza de imágenes locales

**Fase 2 - SonarQube (AKS):**
- Instalación de dependencias Python
- Generación de manifiestos Kubernetes
- Creación de namespace
- Despliegue de PostgreSQL
- Despliegue de SonarQube
- Exposición mediante LoadBalancer

**Fase 3 - WebService (VM):**
- Instalación de paquetes (Podman, OpenSSL)
- Configuración de autenticación básica
- Generación de certificados TLS
- Construcción de imagen personalizada
- Push al ACR
- Despliegue con systemd
- Verificación del servicio

## Verificación del Despliegue

### Verificar Colecciones Instaladas
```bash
ansible-galaxy collection list
```

### Verificar ACR
```bash
# Listar imágenes en ACR
az acr repository list --name <nombre-acr> --output table

# Ver tags de una imagen
az acr repository show-tags --name <nombre-acr> --repository library/httpd
```

### Verificar SonarQube
```bash
# Obtener IP del Service
kubectl get svc -n sonarqube sonarqube

# Ver pods en ejecución
kubectl get pods -n sonarqube

# Acceder a SonarQube
http://<loadbalancer-ip>:1080
# Usuario por defecto: admin
# Contraseña: DevOps-Un1RcP2

# Ver logs de SonarQube
kubectl logs -n sonarqube -l app=sonarqube
```

### Verificar WebService
```bash
# Probar acceso web (desde máquina local)
curl -k -u "dpc-unir:t3st-un1r" https://<webservice_pip>:8080

# Verificar contenedor en la VM
ssh <webservice_pip> "podman ps"
ssh <webservice_pip> "podman images"

# Verificar servicio systemd
ssh <webservice_pip> "systemctl status container-web"

# Ver logs del contenedor
ssh <webservice_pip> "podman logs web"
```

## Uso de Ansible Vault

Los secretos están encriptados con Ansible Vault:

```bash
# Crear archivo vault (si no existe)
ansible-vault create roles/sonarqube/vars/vault.yml

# Editar secretos existentes
ansible-vault edit roles/sonarqube/vars/vault.yml

# Ver contenido encriptado
ansible-vault view roles/sonarqube/vars/vault.yml

# Ejecutar con contraseña manual
ansible-playbook -i environments/production/inventory.azure playbook.yml --ask-vault-pass

# Ejecutar con archivo de contraseña
echo "mi-contraseña" > .vault_pass
ansible-playbook -i environments/production/inventory.azure playbook.yml --vault-password-file .vault_pass
```

## Ejecución por Tags

Puedes ejecutar partes específicas del despliegue usando tags:

```bash
# Solo instalar colecciones (sin despliegue)
ansible-galaxy collection install -r requirements.yml

# Solo desplegar ACR
ansible-playbook -i environments/production/inventory.azure playbook.yml --tags "registry" --ask-vault-pass

# Solo desplegar SonarQube
ansible-playbook -i environments/production/inventory.azure playbook.yml --tags "aks" --ask-vault-pass

# Solo desplegar WebService (no requiere vault)
ansible-playbook -i environments/production/inventory.azure playbook.yml --tags "webservice"

# Modo dry-run (ver qué cambiaría sin aplicarlo)
ansible-playbook -i environments/production/inventory.azure playbook.yml --check --diff
```

## Solución de Problemas

| Problema | Posible Solución |
| :--- | :--- |
| **Error: `community.crypto` no encontrada** | Ejecutar: `ansible-galaxy collection install community.crypto` |
| **Error de autenticación ACR** | Verificar `acr_username/password` en `group_vars/all.yml` |
| **Error de conexión a Kubernetes** | Verificar `kubeconfig` y contexto: `kubectl config current-context` |
| **SonarQube no inicia** | `kubectl logs -n sonarqube deployment/sonarqube` |
| **PostgreSQL no inicia** | `kubectl logs -n sonarqube deployment/postgres` |
| **Puerto 8080 no accesible** | Verificar reglas NSG en Azure |
| **Contenedor web no inicia** | `ssh <webservice_pip> "podman logs web"` |
| **Error de permisos sudo** | Usar `--ask-become-pass` correctamente |
| **Error de vault** | Verificar que la contraseña sea correcta |

## Dependencias del Sistema

### En el nodo de control Ansible:
```bash
# Python y pip
sudo apt update
sudo apt install -y python3-pip python3-venv

# Ansible
pip3 install ansible

# Colecciones (automático con deploy.sh)
ansible-galaxy collection install -r requirements.yml

# Azure CLI (opcional, para verificación)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# kubectl (opcional, para verificación)
sudo az aks install-cli
```

### En las máquinas objetivo:
- **VM WebService**: Ubuntu/Debian con soporte APT
- **AKS**: Clúster Kubernetes ya provisionado
- **ACR**: Registry ya creado en Azure

## Ejemplo de Ejecución Completa

```bash
# 1. Clonar repositorio y entrar al directorio
git clone <repo-url>
cd ansible-project

# 2. Verificar estructura
tree -L 2

# 3. Dar permisos al script
chmod +x deploy.sh

# 4. Ejecutar despliegue
./deploy.sh
# (Se solicitarán: contraseña sudo, contraseña vault)

# 5. Verificar resultados
echo "IP WebService: $(cat group_vars/all.yml | grep webservice_pip)"
echo "Para acceder a SonarQube: kubectl get svc -n sonarqube"
```

## Notas Importantes

1. **Orden de ejecución**: El script `deploy.sh` primero instala las colecciones y luego ejecuta el playbook
2. **Secretos**: Las contraseñas sensibles están en `vault.yml` (encriptado)
3. **Certificados**: El servidor web usa certificados autofirmados (válidos 365 días)
4. **Persistencia**: Los servicios tienen systemd (VM) o PVCs (AKS) para persistencia
5. **Tags**: Útiles para desarrollo y depuración parcial

## Licencia

Apache License Version 2.0 (http://www.apache.org/licenses/)

## Información del Autor

Este playbook fue desarrollado para el caso práctico del Programa Avanzado en DevOps y Cloud.