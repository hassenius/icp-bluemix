
data "ibm_compute_ssh_key" "public_key" {
  label = "${var.key_name}"
}

resource "ibm_compute_vm_instance" "icpmaster" {
    count       = "${var.master["nodes"]}"
    
    datacenter  = "${var.datacenter}"
    domain      = "${var.domain}"
    hostname    = "${format("${lower(var.instance_name)}-master%01d", count.index + 1) }"
    
    os_reference_code = "UBUNTU_16_64"

    cores       = "${var.master["cpu_cores"]}"
    memory      = "${var.master["memory"]}"
    disks       = ["${var.master["disk_size"]}"]
    local_disk  = "${var.master["local_disk"]}"
    network_speed         = "${var.master["network_speed"]}"
    hourly_billing        = "${var.master["hourly_billing"]}"
    private_network_only  = "${var.master["private_network_only"]}"

    user_metadata = "{\"value\":\"newvalue\"}"

    ssh_key_ids = ["${data.ibm_compute_ssh_key.public_key.id}"]
}

resource "ibm_compute_vm_instance" "icpworker" {
    count       = "${var.worker["nodes"]}"

    datacenter  = "${var.datacenter}"
    domain      = "${var.domain}"
    hostname    = "${format("${lower(var.instance_name)}-worker%01d", count.index + 1) }"

    os_reference_code = "UBUNTU_16_64"
    
    cores       = "${var.worker["cpu_cores"]}"
    memory      = "${var.worker["memory"]}"
    disks       = ["${var.worker["disk_size"]}"]
    local_disk  = "${var.worker["local_disk"]}"
    network_speed         = "${var.worker["network_speed"]}"
    hourly_billing        = "${var.worker["hourly_billing"]}"
    private_network_only  = "${var.worker["private_network_only"]}"
    
    user_metadata = "{\"value\":\"newvalue\"}"
    
    ssh_key_ids = ["${data.ibm_compute_ssh_key.public_key.id}"]
}

resource "ibm_compute_vm_instance" "icpproxy" {
    count       = "${var.proxy["nodes"]}"

    datacenter  = "${var.datacenter}"
    domain      = "${var.domain}"
    hostname    = "${format("${lower(var.instance_name)}-proxy%01d", count.index + 1) }"

    os_reference_code = "UBUNTU_16_64"
    
    cores       = "${var.proxy["cpu_cores"]}"
    memory      = "${var.proxy["memory"]}"
    disks       = ["${var.proxy["disk_size"]}"]
    local_disk  = "${var.proxy["local_disk"]}"
    network_speed         = "${var.proxy["network_speed"]}"
    hourly_billing        = "${var.proxy["hourly_billing"]}"
    private_network_only  = "${var.proxy["private_network_only"]}"
    
    user_metadata = "{\"value\":\"newvalue\"}"
    
    ssh_key_ids = ["${data.ibm_compute_ssh_key.public_key.id}"]
}

module "icpprovision" {
    # Bluemix Schematics uses terraform 0.9.8, but icp-deploy module needs 0.10.3 to get local vars
    #source = "github.com/ibm-cloud-architecture/terraform-module-icp-deploy"
    source = "github.com/hassenius/terraform-module-icp-deploy.git?ref=nolocalvar"
    
    icp-master = ["${ibm_compute_vm_instance.icpmaster.ipv4_address}"]
    icp-worker = ["${ibm_compute_vm_instance.icpworker.*.ipv4_address}"]
    icp-proxy = ["${ibm_compute_vm_instance.icpproxy.*.ipv4_address}"]
    
    #icp-version = "2.1.0-beta-1"
    #icp-version = "1.2.0"
    icp-version = "ibmcom/icp-inception:2.1.0-beta-2"

    /* Workaround for terraform issue #10857
     When this is fixed, we can work this out autmatically */

    cluster_size  = "${var.master["nodes"] + var.worker["nodes"] + var.proxy["nodes"]}"

    # Because SoftLayer private network uses 10.0.0.0/8 range, 
    # we will override default ICP network configuration 
    # to be sure to avoid conflict
    icp_configuration = {
      "network_cidr"              = "192.168.0.0/16"
      "service_cluster_ip_range"  = "172.16.0.1/24"
    }

    # We will let terraform generate a new ssh keypair 
    # for boot master to communicate with worker and proxy nodes
    # during ICP deployment
    generate_key = true
    
    # SSH user and key for terraform to connect to newly created SoftLayer resources
    # ssh_key is the private key corresponding to the public keyname specified in var.key_name
    ssh_user  = "root"
    ssh_key   = "~/.ssh/id_rsa"
    
} 

