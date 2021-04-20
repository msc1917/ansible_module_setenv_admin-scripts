# Basis-Ansible-Konfiguration fuer Baikonur-Netzwerk
Rollen-Definitionen zum Einrichten des Heimnetzwerkes

## Rolle "statistics"
Erheben statistischer Daten bei den Hosts

## Verzeichnisse:
* **tasks:** Playbook-Tasks, welche in der Rolle durchgeführt werden
* **defaults:** Standard-Variablen für die Rolle (werden von anderen Variabledefinitionen übersteuert)
* **vars:** Weitere Variablen für die Rolle
* **templates:** Jinja2-Templates, welche von der Rolle benötigt werden könnten
* **files:** Files, welche von der Rolle benötigt werden könnten
* **handlers:** Ansible-Handler-Definitionen
* **meta:** Meta-Daten für die Rolle
