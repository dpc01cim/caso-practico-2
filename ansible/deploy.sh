#!/bin/bash

# Install galaxy collections for ansible.
ansible-galaxy collection install -r requirements.yml

# Playbook for install the Webserver, SonarQube in Azure AKS and Postgres database.
ansible-playbook -i environments/production/inventory.azure playbook.yml --ask-become-pass --ask-vault-pass -v -K
