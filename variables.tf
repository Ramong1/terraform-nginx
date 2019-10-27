variable "location" {}

variable "admin_username" {
    type = "string"
    description = "Administrator user name for virtual machine"
}

variable "computer_name" {
    type = "string"
    description = "Hostname for virtual machine"
}

variable "key_data" {
    type = "string"
    description = "Ssh key login."
}

variable "key_path" {
    type = "string"
    description = "Path for ssh key."
}

variable "tags" {
    type = "string"
    description = "Environment tag for virtual machine."
}


variable "sku" {
    default = {
        westus = "16.04-LTS"
        eastus = "18.04-LTS"
    }
}
