# terraform_ontap_simulator

A terraform solution/plan to deploy/destory an ontap simulator to vmware

## Solution

### Terraform

We start with a terraform plan (`/terraform` folder).  
It basically takes a bunch of variables and deploy an ontap vsim ova file to vcenter.  
So obviously we need some vcenter information, path to the ova file, vm_name, some network names.  
  
The terraform folder needs r/w access (`chmod -R 644 /terraform`).  
The terraform folder needs to be initiator (`terraform init`), to install the providers.  
Terraform needs to be install (duh...)
  
In the folder terraform/ova/netapp we assume you place the vsim ova file, which is not included in this repository

### Ansible

The solution contains out of several steps.  
We try to make this as clean as possible, so we use roles.  
Each role has a main-task where we pass the task we want to run, this makes the playbook very readable.  
Each role has a facts-task where we assemble the variable, that can come from several places and that we merge and flatten.  
Each role has 1 or more action-tasks (create, destroy, ...) depending on the role, which will execute that actual task.  
  
A playbook will generally have a bunch of steps
- load defaults variable `/vars/defaults.yml`
- run facts role - credentials task, to grab the necessary credentials (implement as you wish)
- run the other roles, depending on the playbook (usualy facts + action)

Example : 

```
---
- name: "Day 0 Operations - Deploy Simulator"
  hosts: "localhost"
  become: false
  gather_facts: false
  collections:
    - community.general.terraform
  vars_files:
    - "vars/defaults.yml"

  roles:
    - { role: facts, qtask: credentials }  
    - { role: simulator, qtask: facts }
    - { role: simulator, qtask: plan }    
    - { role: simulator, qtask: create }
    - { role: simulator, qtask: init }    
    - { role: cluster, qtask: facts }       
    - { role: cluster, qtask: create }     
    - { role: aiqum, qtask: facts }        
    - { role: aiqum, qtask: register }         
```

#### Role 'facts'

We have a role facts, that we can call as global starter role, to gather global information.  
For example grabbing the credentials.

#### Role 'ontap_simulator'

This will create and apply (and destroy) the terraform plan, and thus deploy the ova file to vcenter.  
Additionally the init-task will send the necessary key-strokes to the vm (after some sleep) to interupt the vsim setup wizard and create a user and mgmt lif so we can connect to it with the netapp ontap ansible modules.  

#### Role 'cluster'

This will create the cluster and apply some day0 tasks (dns, licenses, timezone, broadcast domains, vlan, ...).  

### Role 'aiqum'

As an extra, the aiqum role allow to (un)register and rediscover the cluster in Netapps 'AIQUM' server (Active IQ Unified Manager).

