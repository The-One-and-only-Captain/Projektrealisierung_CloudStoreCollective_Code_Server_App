# ==============================================================================
# 🛑 PROVIDER CONFIGURATION (MANDATORY)
# Diese Konfiguration ist zwingend erforderlich für die CloudStore-Integration.
# ==============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}
# Authentifizierung und Verbindung zum OpenStack Cloud Provider
# mittels clouds.yaml Datei -> Diese kann auf Openstack erhalten werden.
# Für lokales Testings mittels des Terraform CLIs kann diese sowohl im aktuellen Verzeichnis
# ./terraform abgelegt werden, wie auch für eine projektweite Nutzung
# im Home Verzeichnis ~/.config/openstack/
# für weitere Informationen siehe:
# https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs#using
# WICHTIG: Damit diese App mittels des Cloudstores deployed werden kann,
# MUSS der cloud name "openstack" lauten.
# WICHTIG: Nutzt die clouds.yaml Authentifizierung des Backends
provider "openstack" {
  cloud = "openstack"
}

# ==============================================================================
# 🟢 APP RESOURCES (EXAMPLE)
# Hier beginnt Ihre eigentliche App-Logik.
# ==============================================================================

# Beispiel: Wir lesen ein Image aus (Best Practice)
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04"
  most_recent = true
}

# Beispiel: Eine minimale Instanz, die die Variablen nutzt
resource "openstack_compute_instance_v2" "vm" {
  name      = "${var.app_name}-${var.deployment_id}"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_name = "gp1.small" # In echter App oft via Variable var.flavor_name

  network {
    name = "NAT" # Standard-Netzwerk Name anpassen falls nötig
  }

  # Cloud-Init schreibt alle Inputs in eine Datei (als Beweis, dass sie ankommen)
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    app_name      = var.app_name
    environment   = var.environment
    admins        = join(", ", var.admin_emails)
    backup        = var.enable_backup
    disk          = var.disk_size_gb
  })
}
