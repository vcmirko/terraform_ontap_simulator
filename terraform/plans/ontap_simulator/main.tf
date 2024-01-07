data "vsphere_datacenter" "datacenter" {
  name = var.data_center
}

data "vsphere_datastore" "datastore" {
  name          = var.workload_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = var.compute_host
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "vm_network" {
  name          = var.vm_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "cluster_network" {
  name          = var.cluster_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "vlan_network" {
  name          = var.vlan_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_ovf_vm_template" "ovfLocal" {
  name              = "ontap_simulator"
  disk_provisioning = "thin"
  resource_pool_id  = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id      = data.vsphere_datastore.datastore.id
  host_system_id    = data.vsphere_host.host.id
  local_ovf_path    = var.local_ovf_path
  ovf_network_map = {
    "Cluster Network1" : data.vsphere_network.cluster_network.id
    "Cluster Network2" : data.vsphere_network.cluster_network.id
    "Vlan Network"    : data.vsphere_network.vlan_network.id
    "VM Network"      : data.vsphere_network.vm_network.id
  }
}

## Deployment of VM from Local OVF
resource "vsphere_virtual_machine" "vmFromLocalOvf" {
  name                 = var.vm_name
  datacenter_id        = data.vsphere_datacenter.datacenter.id
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id
  num_cpus             = data.vsphere_ovf_vm_template.ovfLocal.num_cpus
  num_cores_per_socket = data.vsphere_ovf_vm_template.ovfLocal.num_cores_per_socket
  memory               = data.vsphere_ovf_vm_template.ovfLocal.memory
  dynamic "network_interface" {
    for_each = data.vsphere_ovf_vm_template.ovfLocal.ovf_network_map
    content {
      network_id = network_interface.value
      adapter_type = "e1000"
    }
  }
  force_power_off      = true
  wait_for_guest_net_timeout  = 0
  wait_for_guest_ip_timeout   = 0
  wait_for_guest_net_routable = false

  ovf_deploy {
    allow_unverified_ssl_cert = true
    local_ovf_path            = data.vsphere_ovf_vm_template.ovfLocal.local_ovf_path
    disk_provisioning         = data.vsphere_ovf_vm_template.ovfLocal.disk_provisioning
    ip_protocol               = "IPV4"
    ip_allocation_policy      = "STATIC_MANUAL"
    ovf_network_map           = data.vsphere_ovf_vm_template.ovfLocal.ovf_network_map
  }
}
