terraform {
  required_version = ">= 1.6.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
}

# ==============================================================================
# LOCALS
# ==============================================================================
locals {
  # Bei one-per-group bekommt jeder Run eine Map mit genau einem Group-Key.
  # Bei one-instance ist student_groups leer und students enthält die Liste.
  resolved_students = length(var.student_groups) > 0 ? flatten(values(var.student_groups)) : var.students

  # Email → Linux-Username: Local-Part bleibt, Domain-Tokens auf max. 2 Zeichen,
  # hart auf 32 Zeichen begrenzt.
  email_to_username = {
    for email in concat([var.admin_username], local.resolved_students) :
    email => substr(
      lower(join("_", concat(
        [split("@", email)[0]],
        [
          for token in split(".", split("@", email)[1]) :
          join("-", [for part in split("-", token) : substr(part, 0, 2)])
        ]
      ))),
      0, 32
    )
  }

  admin_port = 8080

  # Studierende bekommen Ports 8081, 8082, ... (max 19)
  students_with_ports = [
    for idx, email in local.resolved_students : {
      email    = email
      username = local.email_to_username[email]
      port     = 8081 + idx
    }
  ]
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "openstack_images_image_v2" "ubuntu" {
  count       = var.use_mock_provider ? 0 : 1
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "selected" {
  count = var.use_mock_provider ? 0 : 1
  name  = var.flavor_name
}

data "openstack_networking_network_v2" "external" {
  count    = var.use_mock_provider ? 0 : 1
  name     = var.external_network_name
  external = true
}

# ==============================================================================
# CREDENTIALS
# ==============================================================================

resource "random_password" "admin_password" {
  length           = 20
  special          = true
  override_special = "_-"
}

resource "random_password" "student_passwords" {
  for_each         = toset(local.resolved_students)
  length           = 16
  special          = true
  override_special = "_-"
}

resource "tls_private_key" "code_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "openstack_compute_keypair_v2" "code_keypair" {
  count      = var.use_mock_provider ? 0 : 1
  name       = "code-keypair-${var.deployment_id}"
  public_key = tls_private_key.code_ssh_key.public_key_openssh
}

# ==============================================================================
# SECURITY GROUP
# ==============================================================================

resource "openstack_networking_secgroup_v2" "code_access" {
  count       = var.use_mock_provider ? 0 : 1
  name        = "code-access-${var.deployment_id}"
  description = "Code-Server: SSH + HTTP 8080-8099"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  count             = var.use_mock_provider ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.code_access[0].id
}

resource "openstack_networking_secgroup_rule_v2" "http_ingress" {
  count             = var.use_mock_provider ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8099
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.code_access[0].id
}

# ==============================================================================
# INSTANCE
# ==============================================================================

resource "openstack_compute_instance_v2" "code_server" {
  count           = var.use_mock_provider ? 0 : 1
  name            = "code-${var.deployment_id}"
  image_id        = data.openstack_images_image_v2.ubuntu[0].id
  flavor_id       = data.openstack_compute_flavor_v2.selected[0].id
  key_pair        = openstack_compute_keypair_v2.code_keypair[0].name
  security_groups = [openstack_networking_secgroup_v2.code_access[0].name]

  network {
    name = var.network_name
  }

  depends_on = [openstack_networking_floatingip_v2.code_fip]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    app_name    = var.app_name
    floating_ip = openstack_networking_floatingip_v2.code_fip[0].address

    admin_username = local.email_to_username[var.admin_username]
    admin_email    = var.admin_username
    admin_password = random_password.admin_password.result
    admin_port     = local.admin_port

    students = [
      for s in local.students_with_ports : {
        username = s.username
        email    = s.email
        password = random_password.student_passwords[s.email].result
        port     = s.port
      }
    ]
  })
}

# ==============================================================================
# FLOATING IP
# ==============================================================================

resource "openstack_networking_floatingip_v2" "code_fip" {
  count = var.use_mock_provider ? 0 : 1
  pool  = var.floating_ip_pool
}

resource "openstack_compute_floatingip_associate_v2" "code_fip_assoc" {
  count       = var.use_mock_provider ? 0 : 1
  floating_ip = openstack_networking_floatingip_v2.code_fip[0].address
  instance_id = openstack_compute_instance_v2.code_server[0].id
}

# ==============================================================================
# MOCK RESOURCE
# ==============================================================================

resource "null_resource" "mock_code_server" {
  count = var.use_mock_provider ? 1 : 0
  triggers = {
    deployment_id = var.deployment_id
    app_name      = var.app_name
  }
}
