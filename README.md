# Soly-Simulator

Simulator für PV- und Batterieereignisse der Soly-Pipeline, eingebunden als
Git-Submodule unter `Soly/simulator/`. Bisher sind die Python-Projektgrundlage
und ein Import-Smoke-Test eingerichtet; die Ereignisgenerierung folgt separat.

## Einrichtung

Voraussetzung: **Python 3.12.15**. Alle Befehle im Service-Verzeichnis ausführen.
Falls der Interpreter nicht im Suchpfad liegt, seinen vollständigen Pfad verwenden.

Linux/macOS (Bash/Zsh):

```bash
python3.12 --version
python3.12 -m venv .venv
source .venv/bin/activate
```

Windows (PowerShell):

```powershell
py -3.12 --version
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Anschließend auf allen Plattformen das Paket editierbar samt pytest, Ruff und
mypy installieren; deren Versionen sind in `pyproject.toml` festgelegt:

```bash
python -m pip install -e ".[dev]"
python -m pip check
```

In neuen Shells die vorhandene Umgebung erneut aktivieren; mit `deactivate`
verlassen. `.venv/`, Caches und Build-Artefakte sind über `.gitignore`
ausgeschlossen. Globale Paketinstallationen sind nicht erforderlich.

## Struktur

```text
src/soly_simulator/  Python-Paket
tests/             Import-Smoke-Test und zukünftige Tests
pyproject.toml      Paketmetadaten, Abhängigkeiten und Werkzeugkonfiguration
```

## Prüfungen

In der aktivierten Umgebung:

```bash
python -m pytest                 # Tests
python -m ruff check .           # Linting
python -m ruff format --check .  # Formatprüfung
python -m mypy src tests         # Typprüfung von Quellcode und Tests
```

Zum automatischen Formatieren: `python -m ruff format .`.
