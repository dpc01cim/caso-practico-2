# aks

Rol de Ansible para desplegar SonarQube en un clúster de Azure Kubernetes Service (AKS) utilizando Podman y los módulos de Kubernetes.

## Requisitos

- **Conexión a un clúster AKS**: El nodo de control debe tener acceso configurado al clúster de Kubernetes.
- **Terraform outputs**: Las variables de salida de Terraform deben estar disponibles en `group_vars/all.yml` (especialmente `acr_url`, `tag_image` y `kubeconfig_path`).
- **Rol ACR ejecutado previamente**: Las imágenes necesarias deben estar subidas al Azure Container Registry.
- **Archivo kubeconfig**: Ruta válida al archivo de configuración de Kubernetes.

## Integración con Terraform

Terraform genera automáticamente el archivo `ansible/group_vars/all.yml` con las siguientes variables:

```yaml
# Archivo generado automáticamente por Terraform
acr_url: "nombreacr.azurecr.io"
acr_password: "contraseña_generada"
acr_username: "nombre_usuario"
```

## Estructura de Variables

El rol utiliza variables organizadas en diferentes archivos según su función y sensibilidad.

### Variables en `defaults/main.yml`

Variables con valores por defecto que pueden ser sobrescritas:

| Variable | Descripción | Valor por Defecto |
| :--- | :--- | :--- |
| `apt_packages` | Paquetes APT necesarios para el sistema | `[python3-pip, podman]` |
| `pip_packages` | Paquetes Python para interactuar con Kubernetes | `[pyyaml, kubernetes, openshift]` |
| `k8s_path` | Ruta local para almacenar temporalmente los manifiestos | `/opt/sonar` |
| `k8s_templates` | Lista de plantillas de Kubernetes a procesar | Ver lista completa en `defaults/main.yml` |
| `k8s_namespace` | Namespace de Kubernetes donde desplegar SonarQube | `sonarqube` |

### Variables en `vars/main.yml`

Variables específicas de configuración de los objetos de Kubernetes:

| Variable | Descripción | Estructura |
| :--- | :--- | :--- |
| `deployment` | Configuración del Deployment de SonarQube | `name`, `image`, `replicas`, `containers`, `initContainers` |
| `svc` | Configuración del Service de SonarQube | `name`, `ports`, `type` |
| `pvc` | Configuración del PersistentVolumeClaim | `name`, `accessModes`, `storageClassName`, `storage` |

### Variables de Entorno (develop / production)

Estas variables deben estar definidas en `group_vars/all.yml` o pasarse directamente:

| Variable | Descripción | Fuente |
| :--- | :--- | :--- |
| `acr_url` | URL del Azure Container Registry | Output de Terraform |
| `tag_image` | Tag de las imágenes en ACR | Output de Terraform |
| `kubeconfig_path` | Ruta al archivo kubeconfig | Output de Terraform |

### Variables Secretas (encriptadas)

Las contraseñas se gestionan mediante Ansible Vault en `vault.yml`:

```yaml
# Los secretos deben estar en Base64 en los templates
# Aquí están en claro y se codifican con el filtro | b64encode

# Secret para PostgreSQL
db_password: "********"
```

### Variables de Entrada (Terraform)

| Variable | Descripción | Fuente |
| :--- | :--- | :--- |
| `acr_url` | URL del ACR | `group_vars/all.yml` |
| `acr_username` | Usuario ACR | `group_vars/all.yml` |
| `acr_password` | Contraseña ACR | `group_vars/all.yml` |

## Plantillas (Templates)

El rol incluye las siguientes plantillas Jinja2 en `templates/` que generan los manifiestos de Kubernetes:

| Plantilla | Descripción |
| :--- | :--- |
| `acr-secret.yml.j2` | Secret para autenticación con ACR |
| `sonar-data.yml.j2` | PersistentVolumeClaim para datos de SonarQube |
| `sonar-extensions.yml.j2` | PersistentVolumeClaim para extensiones |
| `postgres-secret.yml.j2` | Secret con credenciales de PostgreSQL |
| `postgres-pvc.yml.j2` | PersistentVolumeClaim para PostgreSQL |
| `postgres-service.yml.j2` | Service para PostgreSQL |
| `postgres-deployment.yml.j2` | Deployment de PostgreSQL |
| `sonar-service.yml.j2` | Service para SonarQube (tipo LoadBalancer) |
| `sonar-deployment.yml.j2` | Deployment principal de SonarQube |

## Flujo de Ejecución

1. **Instalación de dependencias**: Paquetes APT y Python necesarios
2. **Preparación del entorno**: Creación del directorio temporal para manifiestos
3. **Generación de manifiestos**: Procesamiento de todas las plantillas `.j2`
4. **Creación del namespace**: Si no existe, se crea `sonarqube`
5. **Aplicación de manifiestos**: Despliegue secuencial de todos los objetos Kubernetes
6. **Limpieza**: Eliminación del directorio temporal

## Uso del Ansible Vault

Para gestionar los secretos:

```bash
# Editar el archivo vault
ansible-vault edit vault.yml

# Ejecutar el playbook con vault
ansible-playbook playbook.yml --ask-vault-pass

# O usando un archivo de contraseña
ansible-playbook playbook.yml --vault-password-file .vault_pass
```

## Dependencias

- **Ansible Collections**:
  - `kubernetes.core` (para módulos k8s)

- **Roles**:
  - `acr` (debe ejecutarse antes para tener las imágenes en ACR)

## Notas Importantes

1. **Base64**: Los templates convierten automáticamente los secretos a Base64 usando el filtro `| b64encode`
2. **Orden de despliegue**: Los objetos se crean en el orden definido en `k8s_templates` para respetar dependencias
3. **Persistencia**: Los PVCs aseguran que los datos persistan incluso si los pods se recrean

## Licencia

Apache License Version 2.0 (http://www.apache.org/licenses/)

## Información del Autor

Este playbook fue desarrollado para el caso práctico del Programa Avanzado en DevOps y Cloud.