# ==============================================================================
# 🛑 SYSTEM OUTPUTS (MANDATORY)
# Diese Outputs werden vom Backend zur Verwaltung benötigt.
# ==============================================================================

output "instance_id" {
  description = "MANDATORY: Die ID der Haupt-VM für das Backend-Management"
  value       = openstack_compute_instance_v2.vm.id
}

output "app_name" {
  description = "MANDATORY: Der Name der Anwendung für das Backend-Management"
  value       = var.app_name
}

# ==============================================================================
# 🟢 USER OUTPUTS (EXAMPLE)
# Diese Outputs könnten dem Nutzer zur Verfügung gestellt werden (z.B. Credentials).
# ==============================================================================

output "access_ip" {
  description = "IP-Adresse der Anwendung"
  value       = openstack_compute_instance_v2.vm.access_ip_v4
}

output "config_summary" {
  description = "Zusammenfassung der Konfiguration (Debugging)"
  value       = "App: ${var.app_name} | Env: ${var.environment} | Backup: ${var.enable_backup}"
}