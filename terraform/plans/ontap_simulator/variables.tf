# vCenter Variables
variable "data_center" {}
variable "cluster" {}
variable "workload_datastore" {}
variable "compute_pool" {}
variable "compute_host" {}
variable "vsphere_server" {}

# vCenter Credential Variables
variable "vsphere_user" {}
variable "vsphere_password" {}

# custom simulator Variables
variable "vm_network" {}
variable "cluster_network" {}
variable "vlan_network" {}
variable "vm_name" {}
variable "local_ovf_path" {}
