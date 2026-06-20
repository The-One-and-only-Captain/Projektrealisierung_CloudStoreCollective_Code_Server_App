# Code-Server (CloudStore Template)

Self-hosted [code-server](https://github.com/coder/code-server) — VS Code im Browser. Pro Nutzer eine eigene IDE-Instanz mit isoliertem Workspace.

## Features

- Pro Studierendem ein Linux-User + dedizierter Code-Server auf eigenem Port
- Random Passwort pro Nutzer (Browser-Login)
- Dozent erhält Sudo-Rechte auf der VM
- MIT-lizenziert, komplett kostenlos

## Parameter

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `app_name` | string | Name der Instanz (3-20 Zeichen, lowercase) |
| `admin_email` | string | E-Mail des Dozenten (Sudo + eigene Instanz) |
| `student_emails` | array | Studierenden-E-Mails (max. 20) |
| `flavor_name` | selection | `gp1.small` / `gp1.medium` / `gp1.large` |

## Port-Zuweisung

- Admin: `8080`
- Studierende: `8081`, `8082`, … (laut Reihenfolge)

## Outputs

- `ssh_command` — SSH-Zugang zur VM
- `admin_credentials` — Username/Passwort/URL des Dozenten (sensitive)
- `student_credentials` — Zugangsdaten aller Studierenden (sensitive)
- `ssh_private_key` — Private Key (sensitive)

## Ports

- `22/tcp` — SSH
- `8080-8099/tcp` — Code-Server Instanzen
