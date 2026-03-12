# Comandos Útiles de kubectl para Gestionar SonarQube en AKS

Este documento recopila los comandos más utilizados de kubectl para administrar y monitorizar el despliegue de SonarQube en Azure Kubernetes Service (AKS).

## Instalación y Configuración Inicial

```bash
# Instalar kubectl usando snap
sudo snap install kubectl --classic

# Verificar la instalación
kubectl version --client
```

# Configurar contexto de AKS

## Obtener credenciales del clúster AKS (si usas Azure CLI)
```bash
az aks get-credentials --resource-group <resource-group> --name <aks-name>
```

## Ver contexto actual
```bash
kubectl config current-context
```

## Listar todos los contextos disponibles
```bash
kubectl config get-contexts
```

## Cambiar a otro contexto
```bash
kubectl config use-context <context-name>
```

# Comandos Básicos de Información

## Ver nodos del clúster
```bash
### Listar todos los nodos del clúster
kubectl get nodes

### Ver información detallada de los nodos
kubectl get nodes -o wide

### Ver descripción detallada de un nodo específico
kubectl describe node <node-name>
```

## Ver recursos por namespace
```bash
### Listar todos los namespaces
kubectl get namespaces

### Ver pods en todos los namespaces
kubectl get pods --all-namespaces

### Ver servicios en todos los namespaces
kubectl get svc --all-namespaces
```

# Comandos para SonarQube (Namespace: sonarqube)

## Ver pods en el namespace sonarqube
```bash
### Listar todos los pods en el namespace sonarqube
kubectl get pods -n sonarqube

### Ver pods con más detalles (IP, nodo, etc.)
kubectl get pods -n sonarqube -o wide

### Ver pods con etiquetas
kubectl get pods -n sonarqube --show-labels

### Ver pods en modo watch (actualización continua)
kubectl get pods -n sonarqube -w
```

## Ver información detallada de un pod específico
```bash
### Describir un pod para ver eventos y detalles de configuración
kubectl describe pod -n sonarqube sonarqube-7cc8789dc-nbtbx

### Reemplaza 'sonarqube-7cc8789dc-nbtbx' con el nombre de tu pod
```

## Ver servicios (Services)
```bash
### Listar todos los servicios en el namespace sonarqube
kubectl get svc -n sonarqube

### Ver detalles específicos del servicio de SonarQube
kubectl get svc sonarqube -n sonarqube

### Ver servicio con más detalles (incluyendo IP externa)
kubectl get svc sonarqube -n sonarqube -o wide

### Obtener solo la IP externa del LoadBalancer
kubectl get svc -n sonarqube sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

### Ver el servicio PostgreSQL
kubectl get svc postgres -n sonarqube
```

## Ver PersistentVolumeClaims (PVC)
```bash
### Listar todos los PVCs en el namespace sonarqube
kubectl get pvc -n sonarqube

### Ver detalles de un PVC específico (datos de SonarQube)
kubectl get pvc sonarqube -n sonarqube

### Ver PVC con más detalles
kubectl get pvc sonarqube -n sonarqube -o wide

### Ver todos los PVCs del sistema
kubectl get pvc sonarqube sonarqube-extensions postgres-pvc -n sonarqube
```

## Ver Secrets
```bash
### Listar todos los secrets en el namespace sonarqube
kubectl get secrets -n sonarqube

### Ver datos de un secret específico (en base64)
kubectl get secret postgres-db-secret -n sonarqube -o jsonpath='{.data}'

### Decodificar un secret específico (por ejemplo, password)
kubectl get secret postgres-db-secret -n sonarqube -o jsonpath='{.data.password}' | base64 --decode

### Ver todos los datos de un secret decodificados
kubectl get secret postgres-db-secret -n sonarqube -o jsonpath='{.data}' | jq -r 'to_entries[] | "\(.key): \(.value | @base64d)"'
```

# Logs y troubleshooting

## Ver logs de pods
```bash
### Ver logs del pod de PostgreSQL
kubectl logs -n sonarqube postgres-68f8559687-fxvtc

### Ver logs en tiempo real (follow)
kubectl logs -n sonarqube postgres-68f8559687-fxvtc -f

### Ver logs del pod de SonarQube
kubectl logs -n sonarqube sonarqube-7cc8789dc-nbtbx

### Ver logs de los últimos 50 líneas
kubectl logs -n sonarqube sonarqube-7cc8789dc-nbtbx --tail=50

### Ver logs con timestamps
kubectl logs -n sonarqube sonarqube-7cc8789dc-nbtbx --timestamps
```

## Ver eventos del namespace
```bash
### Ver todos los eventos en el namespace sonarqube
kubectl get events -n sonarqube

### Ver eventos ordenados por tiempo
kubectl get events -n sonarqube --sort-by='.lastTimestamp'

### Ver eventos recientes (últimos 10 minutos)
kubectl get events -n sonarqube --watch
```

## Ver logs de PostgreSQL específicos
```bash
### Ver logs de PostgreSQL con información de conexiones
kubectl logs -n sonarqube postgres-68f8559687-fxvtc | grep -i connection

### Ver logs de errores de PostgreSQL
kubectl logs -n sonarqube postgres-68f8559687-fxvtc | grep -i error
```

# Comandos de gestión

## Escalar deployments
```bash
### Escalar SonarQube a 2 réplicas
kubectl scale deployment sonarqube -n sonarqube --replicas=2

### Escalar PostgreSQL a 0 (detener)
kubectl scale deployment postgres -n sonarqube --replicas=0

### Ver el estado del scaling
kubectl get deployment -n sonarqube -w
```

## Reiniciar deployments
```bash
### Reiniciar el deployment de SonarQube
kubectl rollout restart deployment sonarqube -n sonarqube

### Reiniciar PostgreSQL
kubectl rollout restart deployment postgres -n sonarqube

### Ver estado del rollout
kubectl rollout status deployment sonarqube -n sonarqube

### Ver historial de rollouts
kubectl rollout history deployment sonarqube -n sonarqube
```

## Eliminar recursos
```bash
### ¡Cuidado! Eliminar un pod (se recreará automáticamente si está en deployment)
kubectl delete pod -n sonarqube sonarqube-7cc8789dc-nbtbx

### Eliminar un deployment
kubectl delete deployment sonarqube -n sonarqube

### Eliminar un servicio
kubectl delete svc sonarqube -n sonarqube

### Eliminar todo el namespace (¡cuidado! elimina TODO)
kubectl delete namespace sonarqube
```

# Comandos de depuración

## Acceder a un pod interactivamente
```bash
### Acceder al shell del contenedor de PostgreSQL
kubectl exec -it -n sonarqube postgres-68f8559687-fxvtc -- /bin/bash

### Acceder a la consola de PostgreSQL
kubectl exec -it -n sonarqube postgres-68f8559687-fxvtc -- psql -U sonar -d sonarqube

### Ejecutar comando específico sin entrar al shell
kubectl exec -n sonarqube postgres-68f8559687-fxvtc -- psql -U sonar -d sonarqube -c "SELECT * FROM users;"
```

## Port forwarding (acceso local)
```bash
### Redirigir puerto local 9000 al pod de SonarQube
kubectl port-forward -n sonarqube pod/sonarqube-7cc8789dc-nbtbx 9000:9000

### Redirigir servicio completo
kubectl port-forward -n sonarqube service/sonarqube 9000:9000

### Redirigir PostgreSQL para conexión local
kubectl port-forward -n sonarqube service/postgres 5432:5432
```

## Ver recursos utilizados
```bash
### Ver uso de CPU/memoria de los pods
kubectl top pods -n sonarqube

### Ver uso de recursos de los nodos
kubectl top nodes
```


# Comandos útiles con jq para procesar JSON

```bash
### Obtener todos los datos en formato JSON
kubectl get pods -n sonarqube -o json

### Filtrar nombres de pods con jq
kubectl get pods -n sonarqube -o json | jq '.items[].metadata.name'

### Obtener IPs de los pods
kubectl get pods -n sonarqube -o json | jq '.items[].status.podIP'

### Ver estado de los pods formateado
kubectl get pods -n sonarqube -o json | jq '.items[] | {name: .metadata.name, status: .status.phase, node: .spec.nodeName}'
```

# Alias útiles para kubectl

## Alias básicos
```bash
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
```

## Alias para SonarQube
```bash
alias ksonar='kubectl get pods,svc,pvc -n sonarqube'
alias ksonarp='kubectl get pods -n sonarqube'
alias ksonarlogs='kubectl logs -n sonarqube -f deployment/sonarqube'
alias kpostgres='kubectl get pods,svc,pvc -n sonarqube | grep postgres'
alias kpostgresql='kubectl exec -it -n sonarqube deployment/postgres -- psql -U sonar -d sonarqube'
```

## Alias con formato
```bash
alias kgpw='kubectl get pods -n sonarqube -o wide'
alias kgsw='kubectl get svc -n sonarqube -o wide'
```

## Alias para 'describe'
```bash
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdpm='kubectl describe pod -n sonarqube'
```
