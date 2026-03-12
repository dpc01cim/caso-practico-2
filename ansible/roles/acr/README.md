# acr

Rol de Ansible para instalar Podman, autenticarse en un Azure Container Registry (ACR), y subir (push) imágenes de contenedor al mismo.

## Requisitos

- Un Azure Container Registry (ACR) desplegado y accesible desde el nodo de control de Ansible.
- Credenciales de acceso al ACR (nombre de usuario y contraseña).
- El nodo de control donde se ejecute este rol debe ser accesible y tener conexión a internet para descargar las imágenes de origen.

## Variables

A continuación, se describen las variables que utiliza el rol. Los valores por defecto se encuentran en `defaults/main.yml` y pueden ser sobrescritos en inventarios o playbooks.

| Variable | Descripción | Valor por Defecto |
| :--- | :--- | :--- |
| `podman_packages` | Lista de paquetes de Podman a instalar. | `[podman, skopeo]` |
| `acr_url` | URL del Azure Container Registry. | `container.registry.unir.net` |
| `acr_username` | Nombre de usuario para autenticarse en el ACR. | `username` |
| `acr_password` | Contraseña para autenticarse en el ACR. | `test12345` |
| `acr_images` | Lista de imágenes a procesar. Cada elemento es un diccionario con las claves `src` (imagen de origen) y `dest` (nombre del repositorio en el ACR). | Ver `defaults/main.yml` |
| `tag_image` | Tag que se aplicará a las imágenes al ser subidas al ACR. | `casopractico2` |

### Ejemplo de `acr_images`

La variable `acr_images` tiene una estructura específica:

```yaml
acr_images:
  - src: "docker.io/library/httpd:alpine"
    dest: "library/httpd"
  - src: "docker.io/library/sonarqube:community"
    dest: "library/sonarqube"
  - src: "docker.io/library/postgres:17.9-alpine"
    dest: "library/postgres"
```

*   **`src`**: Es la imagen de origen completa, incluyendo el tag. Se usa para hacer `pull` desde el registro público.
*   **`dest`**: Es el nombre del repositorio (sin la URL base del ACR y sin el tag) donde se almacenará la imagen. El rol construirá el nombre destino como `{{ acr_url }}/{{ item.dest }}:{{ tag_image }}`.

## Dependencias

Ninguna.

## Licencia

Apache License Version 2.0 (http://www.apache.org/licenses/)

## Información del Autor

Este playbook fue desarrollado para el caso práctico del Programa Avanzado en DevOps y Cloud.