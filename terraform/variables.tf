# ==============================================================================
# 🛑 SYSTEM VARIABLES (DO NOT TOUCH)
# Diese Variablen werden vom CloudStore Backend injiziert.
# ==============================================================================

variable "deployment_id" {
  description = "Eindeutige ID des Deployments"
  type        = string
}

# --- 1. String Validation (Regex) ---
variable "app_name" {
  type        = string
  description = "Beispiel für Text-Validierung"
  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.app_name))
    error_message = "app_name: Nur Kleinbuchstaben, Zahlen und Bindestrich erlaubt (3-20 Zeichen)."
  }
}

# ==============================================================================
# 🟢 APP PARAMETERS (REFERENCE EXAMPLES)
# Kopieren Sie die passenden Blöcke für Ihre App.
# ==============================================================================


# --- 2. Selection Validation (Whitelist) ---
variable "environment" {
  type        = string
  description = "Beispiel für Dropdown-Validierung"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment: Muss entweder 'dev' oder 'prod' sein."
  }
}

# --- 3. Array Validation (List Check) ---
variable "admin_emails" {
  type        = list(string)
  description = "Beispiel für Listen-Validierung"
  validation {
    condition     = length(var.admin_emails) > 0 && length(var.admin_emails) <= 5
    error_message = "admin_emails: Mindestens 1, maximal 5 E-Mails."
  }
  # Profi-Tipp: Validierung jedes einzelnen Eintrags
  validation {
    condition = alltrue([
      for email in var.admin_emails : can(regex("^\\S+@\\S+\\.\\S+$", email))
    ])
    error_message = "Alle Einträge in admin_emails müssen gültige E-Mail-Adressen sein."
  }
}

# --- 4. Boolean (Keine Validierung nötig) ---
variable "enable_backup" {
  type    = bool
  default = false
}

# --- 5. Number Validation (Range) ---
variable "disk_size_gb" {
  type        = number
  description = "Beispiel für Zahlen-Validierung"
  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 100
    error_message = "disk_size_gb: Muss zwischen 10 und 100 GB liegen."
  }
}