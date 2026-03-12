# webservice

Rol de Ansible para desplegar y configurar un servidor web con autenticación básica, TLS/SSL y containerización usando Podman en una máquina virtual de Azure.

## Requisitos

- **Máquina virtual Ubuntu** (o compatible con APT) en Azure
- **Conexión a ACR**: Acceso al Azure Container Registry para almacenar y recuperar imágenes
- **Terraform outputs**: Variables generadas automáticamente por Terraform en `group_vars/all.yml`
- **Rol ACR ejecutado previamente**: Las imágenes base deben estar disponibles en el registro
- **Puerto 8080 abierto**: En el grupo de seguridad de red (NSG) de la VM

## Integración con Terraform

Terraform genera automáticamente el archivo `ansible/group_vars/all.yml` con las siguientes variables:

```yaml
# Archivo generado automáticamente por Terraform
acr_url: "nombreacr.azurecr.io"
acr_password: "contraseña_generada"
acr_username: "nombre_usuario"
webservice_pip: "XX.XXX.XXX.XX"
```

Estas variables son utilizadas por el rol para:
- Autenticarse en ACR (`acr_username`, `acr_password`, `acr_url`)
- Verificar el despliegue (`webservice_pip`)

## Estructura de Variables

El rol utiliza variables organizadas en diferentes archivos según su función.

### Variables en `defaults/main.yml`

Variables con valores por defecto (pueden ser sobrescritas):

| Variable | Descripción | Valor por Defecto |
| :--- | :--- | :--- |
| `apt_packages` | Paquetes a instalar en el sistema | `[apache2-utils, openssl, podman, skopeo, python3-passlib, python3-openssl]` |
| `username` | Usuario para autenticación básica | `test` |
| `password` | Contraseña para autenticación básica | `test` |
| `webserver_path` | Ruta local para archivos del servidor | `/opt/webserver` |
| `server_container_path` | Ruta dentro del contenedor | `/usr/local/apache2` |
| `server_hostname` | Hostname para certificados TLS | `ws-caso-practico-2` |
| `key_size` | Tamaño de la clave TLS/SSL | `2048` |
| `passphrase` | Frase de paso para la clave privada | `(vacío)` |
| `key_type` | Algoritmo para la clave TLS/SSL | `RSA` |
| `container_templates` | Plantillas de configuración | Ver lista completa abajo |
| `podman_image` | Nombre de la imagen en ACR | `"{{ acr_url }}/library/httpd:{{ tag_image }}"` |
| `tag_image` | Tag de la imagen | `casopractico2` |
| `custom_image` | Nombre para imagen personalizada | `/custom/webserver` |
| `container_web_service` | Ruta para servicios systemd | `/etc/systemd/system/` |
| `container_prefix` | Prefijo para servicios systemd | `container` |
| `acr_url` | URL del ACR | `registry.unir.net` |
| `acr_username` | Usuario ACR | `admin` |
| `acr_password` | Contraseña ACR | `Harbor54321` |

### Variables en `vars/main.yml`

Sobrescrituras específicas del entorno (más seguras):

| Variable | Descripción | Valor |
| :--- | :--- | :--- |
| `username` | Usuario para autenticación | `dpc-unir` |
| `password` | Contraseña para autenticación | `t3st-un1r` |
| `key_type` | Algoritmo TLS/SSL | `RSA` |

### Variables de Entrada (desde Terraform)

| Variable | Descripción | Fuente |
| :--- | :--- | :--- |
| `acr_url` | URL del ACR | `group_vars/all.yml` |
| `acr_username` | Usuario ACR | `group_vars/all.yml` |
| `acr_password` | Contraseña ACR | `group_vars/all.yml` |
| `webservice_pip` | IP pública de la VM | `group_vars/all.yml` |

## Plantillas (Templates)

El rol incluye las siguientes plantillas Jinja2 en `templates/`:

| Plantilla | Descripción |
| :--- | :--- |
| `index.html.j2` | Página web por defecto con autenticación |
| `.htaccess.j2` | Configuración de autenticación básica |
| `httpd.conf.j2` | Configuración principal de Apache HTTPD |
| `Containerfile.j2` | Instrucciones para construir la imagen personalizada |

## Flujo de Ejecución

### 1. Preparación del Sistema
- Actualización de paquetes del sistema
- Instalación de dependencias (Podman, OpenSSL, etc.)

### 2. Configuración de Seguridad
- Creación de archivo `.creds` con autenticación básica (`htpasswd`)
- Generación de clave privada RSA
- Creación de CSR (Certificate Signing Request)
- Generación de certificado autofirmado (válido por 365 días)

### 3. Construcción de la Imagen
- Copia de archivos de configuración desde plantillas
- Construcción de imagen personalizada usando `Containerfile.j2`
- Push de la imagen al ACR

### 4. Despliegue del Contenedor
- Creación de contenedor Podman con:
  - Puerto `8080` expuesto (mapeado a `443` del contenedor)
  - Generación automática de servicio systemd
  - Variables de entorno dinámicas (fecha, hostname, entorno)

### 5. Verificación y Limpieza
- Test de conectividad al servidor web
- Autenticación básica validada
- Limpieza de archivos temporales

## Configuración del Contenedor

El contenedor resultante tiene las siguientes características:

- **Imagen base**: `httpd:alpine` (desde ACR)
- **Puerto expuesto**: `8080` (https)
- **Autenticación**: Básica (archivo `.creds`)
- **TLS/SSL**: Certificado autofirmado
- **Persistencia**: Servicio systemd para auto-arranque
- **Etiquetas**: Información de despliegue en variables de entorno

## Verificación del Despliegue

Una vez ejecutado el rol, puedes verificar el despliegue:

```bash
# Verificar el contenedor en ejecución
podman ps

# Verificar el servicio systemd
systemctl status container-web

# Probar acceso web (desde otra máquina)
curl -k -u "dpc-unir:t3st-un1r" https://$(webservice_pip):8080

# Ver logs del contenedor
podman logs web
```

## Dependencias

- **Ansible Collections**:
  - `community.general` (módulo `htpasswd`)
  - `community.crypto` (módulos SSL/TLS)
  - `containers.podman` (módulos Podman)

- **Roles**:
  - `acr` (debe ejecutarse antes para tener la imagen base en ACR)

## Notas Importantes

1. **Certificados autofirmados**: El certificado generado es autofirmado; los navegadores mostrarán advertencia de seguridad
2. **Autenticación**: La combinación usuario/contraseña debe coincidir en los archivos de configuración
3. **Persistencia**: El servicio systemd asegura que el contenedor se reinicie automáticamente
4. **Seguridad**: Las contraseñas deberían gestionarse con Ansible Vault en producción

## Solución de Problemas

| Problema | Posible Solución |
| :--- | :--- |
| Error de conexión al ACR | Verificar `acr_username` y `acr_password` en `group_vars/all.yml` |
| Puerto 8080 no accesible | Verificar reglas NSG en Azure |
| Error de autenticación | Revisar archivo `.creds` y configuración `.htaccess` |
| Contenedor no inicia | Ver logs con `podman logs web` |

## Licencia

Apache License Version 2.0 (http://www.apache.org/licenses/)

## Información del Autor

Este playbook fue desarrollado para el caso práctico del Programa Avanzado en DevOps y Cloud.