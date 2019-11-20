variable "admin_username" {
    description = "VM local admin username"
}
variable "admin_password" {
    description = "Local admin password. Should be fed from keyvault. Do not specify in plain text. "
}
variable "location" {
    default = "West Europe"
}
variable "subnet_id" {
    description = "Subnet to place the VM"
}
variable "dns_servers" {
    default = []
    description = "DNS servers for VM(s). Will override VNET settings."
}
variable "availability_set_context" {
    description = "Availability set context that forms part of the name E.G DS-CONTEXT-AS"
}
variable "resource_group_name" {
    description = "Resource group for the virtual machine"
}
variable "service_short_name" {
    description = "DS, APP, DB, WEB, MGT, SEC, FIL etc"
}
variable "vm_user_properties" {
    type = "map"
    description = "Should contain a VM number with Private_ip, Patchwindow and VM_size values. See example below."
    /*
    "001" = {
        "Private_ip"  = "10.220.2.4"
        "Patchwindow" = "WIN-T1-PatchWeekend"
        "VM_size"     = "Standard_B2s"
    }
    "002" = {
        "Private_ip"  = "10.220.2.5"
        "Patchwindow" = "WIN-T2-PatchWeekend"
        "VM_size"     = "Standard_B2s"
    }
    */
}
variable "tags" {
    type = "map"
    description = "Common tags. Environment tag required for generating the VM name"
}
variable "os_disk_type" {
    default = "Standard_LRS"
    description = "Specifies the type of managed disk to create. Possible values: Standard_LRS, StandardSSD_LRS, Premium_LRS"
}
variable "data_disk_type" {
    default = ""
    description = "If specified will create a data disk. Possible values: Standard_LRS, StandardSSD_LRS, Premium_LRS"
}
variable "data_disk_size_gb" {
    default = ""
    description = "Required when specifying a data disk above"
}

variable "active_directory_domain" {
    default = ""
    description = "AD domain to join"
}

variable "active_directory_username" {
    default = ""
    description = "AD user with join domain rights"
}

variable "active_directory_password" {
    default = ""
    description = "AD user with join domain rights password"
}

//variable "backup_policy_name" {}
//variable "recovery_vault_name" {}
//variable "recovery_vault_resource_group_name" {}