# ==============================================================================
# SYSTEM VARIABLES
# ==============================================================================

variable "deployment_id" {
  description = "Eindeutige ID des Deployments"
  type        = string
  validation {
    condition     = length(var.deployment_id) > 0
    error_message = "deployment_id darf nicht leer sein."
  }
}

variable "use_mock_provider" {
  description = "Falls true: kein echter OpenStack-Aufruf (für lokale Tests)"
  type        = bool
  default     = false
}

# ==============================================================================
# APP PARAMETERS
# ==============================================================================

variable "app_name" {
  type        = string
  description = "Name der Code-Server-Instanz"
  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.app_name))
    error_message = "app_name: Nur Kleinbuchstaben, Zahlen und Bindestriche erlaubt (3-20 Zeichen)."
  }
}

variable "admin_username" {
  type        = string
  description = "E-Mail des Dozenten (eigene Code-Server-Instanz + Sudo auf der VM)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_username))
    error_message = "admin_username muss eine gültige E-Mail-Adresse sein."
  }
}

# Befüllt bei deploy-strategy = one-instance
variable "students" {
  type        = list(string)
  description = "E-Mails der Studierenden (one-instance mode)"
  default     = []

  validation {
    condition     = length(var.students) <= 19
    error_message = "students: Maximal 19 (zusammen mit Admin = 20 Code-Server-Instanzen, Ports 8080-8099)."
  }
  validation {
    condition = alltrue([
      for email in var.students : can(regex("^\\S+@\\S+\\.\\S+$", email))
    ])
    error_message = "Alle Einträge in students müssen gültige E-Mail-Adressen sein."
  }
}

# Befüllt bei deploy-strategy = one-per-group
variable "student_groups" {
  type        = map(list(string))
  description = "Map of group name -> list of student emails (one-per-group mode)"
  default     = {}

  validation {
    condition = alltrue([
      for emails in values(var.student_groups) : alltrue([
        for email in emails : can(regex("^\\S+@\\S+\\.\\S+$", email))
      ])
    ])
    error_message = "All emails in student_groups must be valid."
  }
}

variable "flavor_name" {
  type        = string
  description = "OpenStack Flavor (VM-Größe)"
  default     = "gp1.medium"
  validation {
    condition     = contains(["gp1.small", "gp1.medium", "gp1.large"], var.flavor_name)
    error_message = "flavor_name: Muss 'gp1.small', 'gp1.medium' oder 'gp1.large' sein."
  }
}

# ==============================================================================
# INFRASTRUCTURE DEFAULTS
# ==============================================================================

variable "image_name" {
  type    = string
  default = "Ubuntu 22.04"
}

variable "network_name" {
  type    = string
  default = "NAT"
}

variable "external_network_name" {
  type    = string
  default = "DHBW"
}

variable "floating_ip_pool" {
  type    = string
  default = "DHBW"
}
