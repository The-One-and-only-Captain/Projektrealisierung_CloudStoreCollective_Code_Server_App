# Code-Server (VS Code im Browser)

Self-hosted [code-server](https://github.com/coder/code-server) — VS Code im Browser. Pro Studierendem eine isolierte IDE-Instanz auf eigenem Port mit eigenem Linux-User und Passwort-Schutz.

## Konzept

Eine VM hostet **mehrere unabhängige Code-Server-Instanzen** — eine pro Linux-User. Jeder Studierende öffnet seine **eigene URL** mit eigenem Port (8080-8099), loggt sich mit seinem Passwort ein und arbeitet in seinem isolierten Workspace.

Der Dozent bekommt ebenfalls eine eigene Instanz + Sudo-Rechte auf der VM.

**Deploy-Strategien:**

- **`one-instance`** — eine VM für den ganzen Kurs, alle Studierenden als Code-Server-Instanzen auf Ports darauf (max 19 Studis + Dozent = 20 Ports)
- **`one-per-group`** — eine VM pro Projektgruppe, Mitglieder als Code-Server-Instanzen darauf

`one-per-user` ist bewusst nicht aktiviert.

## Parameter

### Allgemein

| Parameter | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `app_name` | string | ja | Identifier |
| `admin_username` | email (user-picker) | ja | Dozent, eigene Instanz + Sudo |
| `students` | list(email) (user-picker, multi) | bei `one-instance` | Studierende (max 19) |
| `student_groups` | groups (group-builder) | bei `one-per-group` | Projektgruppen |

### Ressourcen

| Parameter | Typ | Default | Beschreibung |
|---|---|---|---|
| `flavor_name` | selection | `gp1.medium` | Small (~5 Nutzer), Medium (~10), Large (~20) |

## Port-Zuweisung

| User | Port |
|---|---|
| Admin (Dozent) | 8080 |
| Student 1 | 8081 |
| Student 2 | 8082 |
| ... | ... |
| Student N | 8080 + N |

Bei `one-per-group` startet die Nummerierung pro VM neu — Admin auf 8080, Gruppenmitglieder ab 8081.

## Outputs

| Output | Sichtbar | Sensitive | Beschreibung |
|---|---|---|---|
| `instance_id` | nein | nein | VM-ID (intern) |
| `app_name` | ja | nein | Projektname |
| `ssh_command` | ja | nein | SSH-Vorlage (Admin-Zugang via Key) |
| `admin_credentials` | nein | ja | Dozenten-Login + persönliche code_url |
| `student_credentials` | nein | ja | Map email → {username, email, password, code_url} |
| `ssh_private_key` | nein | ja | SSH Private Key (RSA 4096) |

## Setup-Ablauf (cloud-init)

1. Ubuntu 22.04 + Basispakete (`curl`, `ca-certificates`, `ufw`, `sudo`)
2. UFW: Ports 22, 8080-8099
3. code-server installieren (offizielles Skript von `code-server.dev`)
4. Systemd Template-Unit `code-server@<username>.service` für Multi-Instance-Support
5. **Pro User** (`setup_user.sh`):
   - Linux-User anlegen, Passwort setzen
   - Admin zusätzlich in `sudo`-Gruppe
   - Config in `/home/<user>/.config/code-server/config.yaml`:
     - `bind-addr: 0.0.0.0:<port>`
     - `auth: password` + Passwort
     - `cert: true` → code-server generiert Self-Signed Cert
   - Workspace-Ordner `/home/<user>/workspace`
   - Systemd-Service aktivieren und starten

## Username-Konvention

E-Mails werden zu Linux-Usernames konvertiert. Local-Part bleibt, jedes Domain-Token wird auf max. 2 Zeichen gekürzt.

| Email | Username |
|---|---|
| `s2327001@student.dhbw-mannheim.de` | `s2327001_st_dh-ma_de` |
| `prof1@dhbw-mannheim.de` | `prof1_dh-ma_de` |

## Zugriff

### Studierende

1. Browser öffnen: `code_url` aus `student_credentials[<eigene-email>]` (`https://<floating-ip>:<port>`)
2. **Self-Signed Cert akzeptieren** — Browser-Warnung wegklicken
3. Login mit dem **Passwort** aus den Credentials (kein separater Username — code-server hat ein einzelnes Passwort pro Instanz)
4. Arbeitsumgebung: `/home/<username>/workspace`
5. **Terminal im Browser:** Code-Server bietet integriertes Terminal mit dem eigenen Linux-User

### Dozent (Admin)

1. **Eigene Code-Server-Instanz** auf Port 8080 mit Sudo-Rechten auf der VM
2. **Web-Login:** `admin_credentials.code_url` mit `admin_credentials.password`
3. **VM per SSH:**
   ```bash
   ssh -i ./key.pem ubuntu@<floating-ip>

   # Status der Code-Server-Instanzen
   sudo systemctl status 'code-server@*'

   # Logs einer einzelnen Instanz
   sudo journalctl -u code-server@<username>.service -f

   # Instanz neustarten
   sudo systemctl restart code-server@<username>.service

   # Übersicht aller User
   cat /etc/cloudstore/code_info.txt
   ```

### Typische Admin-Aufgaben

```bash
# Passwort eines Studis ändern (auf der VM)
sudo passwd <username>

# Code-Server Passwort für einen User ändern
sudo vim /home/<username>/.config/code-server/config.yaml   # password-Zeile anpassen
sudo systemctl restart code-server@<username>.service

# Wer arbeitet gerade
sudo systemctl list-units 'code-server@*' --type=service
```

## Ports

| Port | Zweck |
|---|---|
| 22 | SSH (Admin via Key) |
| 8080 | Admin Code-Server (HTTPS, Self-Signed) |
| 8081-8099 | Studierenden Code-Server (HTTPS, Self-Signed) |

## Hinweise

- **Self-Signed Cert pro Instanz:** Jede Code-Server-Instanz generiert ihr eigenes Zertifikat beim ersten Start. Browser warnt einmalig pro URL/Port-Kombination.
- **Workspace ist VM-lokal:** Bei VM-Destroy gehen Dateien verloren. Studierende sollten regelmäßig `git push` machen.
- **Ressourcenteilung:** Bei N parallelen Nutzern teilen sich alle die VM-Ressourcen. Für rechenintensive Sessions Large-Flavor wählen.
