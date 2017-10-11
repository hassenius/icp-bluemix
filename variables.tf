variable "key_name" { 
  description = "Name or reference of SSH key to provision softlayer instances with"
  default = "hk_key"
}


##### Common VM specifications ######
variable "datacenter" { default = "ams03" }
variable "domain" { default = "ibmcloud.private" }

# Name of the ICP installation, will be used as basename for VMs
variable "instance_name" { default = "myicp" }
