# ==============================================================================
# SYSTEM OUTPUTS (MANDATORY)
# ==============================================================================

output "instance_id" {
  description = "VM ID for backend management"
  value       = var.use_mock_provider ? "mock-instance-${var.deployment_id}" : openstack_compute_instance_v2.code_server[0].id
}

output "app_name" {
  description = "Project name"
  value       = var.app_name
}

# ==============================================================================
# PUBLIC OUTPUTS
# ==============================================================================

output "ssh_command" {
  description = "SSH-Befehl für den VM-Zugang"
  value       = var.use_mock_provider ? "ssh ubuntu@mock-ip" : "ssh -i <private_key> ubuntu@${openstack_networking_floatingip_v2.code_fip[0].address}"
}

# ==============================================================================
# SENSITIVE OUTPUTS
# ==============================================================================

output "admin_credentials" {
  description = "Admin-Zugangsdaten des Dozenten (eigene Code-Server-Instanz + Sudo)"
  sensitive   = true
  value = {
    username = local.email_to_username[var.admin_username]
    email    = var.admin_username
    password = random_password.admin_password.result
    code_url = var.use_mock_provider ? "https://mock-ip:${local.admin_port}" : "https://${openstack_networking_floatingip_v2.code_fip[0].address}:${local.admin_port}"
  }
}

output "student_credentials" {
  description = "Zugangsdaten aller Studierenden"
  sensitive   = true
  value = {
    for s in local.students_with_ports : s.email => {
      username = s.username
      email    = s.email
      password = random_password.student_passwords[s.email].result
      code_url = var.use_mock_provider ? "https://mock-ip:${s.port}" : "https://${openstack_networking_floatingip_v2.code_fip[0].address}:${s.port}"
    }
  }
}

output "ssh_private_key" {
  description = "SSH Private Key für den VM-Zugang"
  sensitive   = true
  value       = tls_private_key.code_ssh_key.private_key_openssh
}
