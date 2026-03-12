# Caso Práctico 2: Automatización de despliegues en entornos Cloud
El caso práctico 2 se enfoca en despliegues de aplicaciones sobre la nube pública Cloud de Microsoft Azure mediante el uso de herramientas DevOps (terraform y ansible).

## Objetivos del Caso Práctico 2

### Esta actividad tiene los siguientes objetivos:

- Crear infraestructura de forma automatizada en un proveedor de Cloud pública (Azure).
- Utilizar herramientas de gestión de la configuración para automatizar la instalación y configuración de servicios (Ansible).
- Desplegar mediante un enfoque totalmente automatizado, aplicaciones en forma de contenedor sobre el sistema operativo (Ansible).
- Desplegar mediante un enfoque totalmente automatizado, aplicaciones que hagan uso de almacenamiento persistente sobre una plataforma de orquestación de contenedores (Ansible).

## Descripción de la actividad

### El caso práctico 2 consiste en desplegar los siguientes elementos:

- Un (1) repositorio de imágenes de contenedores sobre infraestructura de Microsoft Azure mediante el servicio Azure Container Registry (ACR).
- Una (1) aplicación en forma de contenedor utilizando Podman sobre una máquina
virtual en Azure.
- Un (1) cluster de Kubernetes como servicio gestionado en Microsoft Azure (AKS).
- Una (1) aplicación con almacenamiento persistente sobre el clúster AKS.

Se debe realizar de forma automática mediante Ansible la instalación y configuración de los siguientes elementos:

- Un (1) servidor Web desplegado en forma de contenedor de Podman sobre una máquina virtual en Azure.
- Una (1) aplicación con almacenamiento persistente sobre el cluster AKS.

## Formato del Repositorio Git

El repositorio debe tener el siguiente formato:

```
├── ansible
│   ├── deploy.sh
│   ├── hosts
│   ├── playbook.yml
└── terraform
    ├── vars.tf
    ├── main.tf
    └── recursos.tf
```


El directorio **ansible** debe contener:

* deploy.sh - Script de bash que ejecuta el playbook de Ansible.

* hosts - Fichero de inventario

* playbook.yml - Uno o más ficheros de playbook.

El directorio **terraform** debe incluir:

* vars.tf - Fichero que incluye al menos las siguientes variables:

```
variable "location" {
  type = string
  description = "Región de Azure donde crearemos la infraestructura"
  default = "<YOUR REGION>" 
}
```

## License

Licensed under the Apache License, Version 2.0. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
