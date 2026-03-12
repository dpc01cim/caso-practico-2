[vm]
${webservice_pip} ansible_user=azureuser ansible_ssh_private_key_file=${private_key_path}

[acr]
localhost ansible_connection=local

[aks]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
