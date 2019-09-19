provider "alicloud" {
  region     = "cn-beijing"
}

# Create a new ECS instance for VPC
resource "alicloud_vpc" "vpc" {
    name       = "tf_ansible"
    cidr_block = "192.168.0.0/24"
}

resource "alicloud_vswitch" "vswitch" {
    vpc_id = "${alicloud_vpc.vpc.id}"
    cidr_block        = "192.168.0.0/24"
    availability_zone = "cn-beijing-b"
}

resource "alicloud_security_group" "group" {
  name        = "terraform-ansible-group"
  description = "New security group"
  vpc_id = "${alicloud_vpc.vpc.id}"
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "internet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = "${alicloud_security_group.group.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_key_pair" "publickey" {
  key_name   = "my_public_key"
  public_key = "${file(var.public_key)}"
}

resource "alicloud_instance" "instance" {
  # cn-beijing
  availability_zone = "cn-beijing-b"
  security_groups   = ["${alicloud_security_group.group.id}"]

  # series III
  instance_type              = "ecs.n1.tiny"
  system_disk_category       = "cloud_efficiency"
  image_id                   = "ubuntu_16_04_64_20G_alibase_20190620.vhd"
  instance_name              = "tf_ansible"
  vswitch_id                 = "${alicloud_vswitch.vswitch.id}"
  internet_max_bandwidth_out = 5
  key_name  = "${alicloud_key_pair.publickey.key_name}"

  connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file(var.ssh_key_private)}"
  }

  provisioner "remote-exec" {
    inline = ["sudo apt-get -qq install python -y"]

  }
  provisioner "local-exec" {
    command = "ansible-playbook -u root -i '${self.public_ip},' --private-key ${var.ssh_key_private} ../playbooks/install_java.yaml" 
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u root -i '${self.public_ip},' --private-key ${var.ssh_key_private} ../playbooks/install_jenkins.yaml" 
  }
}