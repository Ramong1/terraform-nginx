# terraform-nginx
Deploy an ubuntu VM on Azure. Install nginx using salt and run it on multiple ports.

To use you will need to populate the terraform.tfvars file variables with what works for you. For example,


location = "prefered location"

admin_username = "some_user_name"

computer_name = "a_host_name"

key_data = "ssh-rsa H9UG.....yip"

key_path = "/home/some_user_name/.ssh/authorized_keys"

tags = "My Terraform VM"


You will need to create an ssh key and paste that public key in the value for key_data.

...
