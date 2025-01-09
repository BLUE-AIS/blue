resource "null_resource" "create_template" {
    connection {
		type	=	"ssh"
		user	=	var.ssh_user_prox
		host	=	var.ssh_host_prox
		private_key = file(var.ssh_key)
    }

provisioner "file" {
	 source	=	"01.1_create_env_pve.sh"
	 destination = "/tmp/create_templates_qemu.sh"
	}

	        
provisioner "remote-exec" {
	inline= [
        "cp /tmp/create_templates_qemu.sh .",
        "chmod +x create_templates_qemu.sh",
        "sh create_templates_qemu.sh"
         ]
  }
}

	   
       

