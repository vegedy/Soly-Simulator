# Soly-Simulator

Datensimulation für die Soly-Pipeline. Das eigenständige Service-Repository wird
im Hauptrepository `Soly` als Git-Submodule unter `simulator/` eingebunden.

## Voraussetzungen

- Python **3.12.15** gemäß den Soly-Technologieentscheidungen. Die Version ist
  in `pyproject.toml` exakt festgelegt.
- Alle folgenden Befehle werden im Stammverzeichnis dieses Service-Repositories
  ausgeführt, also bei Verwendung des Hauptrepositories in `Soly/simulator/`.

Jeder Python-Service erhält eine eigene virtuelle Umgebung. `.venv/` wird über
`.gitignore` von Git ausgeschlossen und auf jedem Rechner neu erstellt.

## Virtuelle Umgebung erstellen und aktivieren

### Linux und macOS (Bash/Zsh)

Zuerst prüfen, dass der verwendete Interpreter exakt Python 3.12.15 ist:

```bash
python3.12 --version
python3.12 -m venv .venv
source .venv/bin/activate
```

Falls Python nicht über `python3.12` erreichbar ist, beim Erstellen den
vollständigen Pfad zum passenden Interpreter verwenden. Auf dem aktuellen
Entwicklungsrechner wurde Python separat im Benutzerverzeichnis installiert:

```bash
/home/benito/.local/opt/python/3.12.15/bin/python3.12 -m venv .venv
source .venv/bin/activate
```

Diese beiden Varianten sind Alternativen. Eine bereits vorhandene `.venv`
muss für die tägliche Nutzung nur aktiviert werden.

### Windows (PowerShell)

Mit dem Python-Launcher prüfen, dass Python 3.12.15 ausgewählt wird:

```powershell
py -3.12 --version
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Alternativ in der Windows-Eingabeaufforderung (`cmd.exe`) aktivieren:

```bat
.venv\Scripts\activate.bat
```

Nach der Aktivierung auf allen Plattformen die Umgebung prüfen:

```bash
python --version
python -c "import sys; print(sys.executable)"
python -m pip --version
```

Erwartet werden Python 3.12.15 sowie Interpreter und pip aus der lokalen `.venv`.

## Projekt und Entwicklungsabhängigkeiten installieren

In der aktivierten Umgebung:

```bash
python -m pip install -e ".[dev]"
python -m pip check
```

Die editierbare Installation (`-e`) macht das Paket `soly_simulator` aus `src/`
importierbar. Änderungen am Python-Quellcode werden ohne erneute Installation
wirksam. Nach Änderungen an Abhängigkeiten oder Paketmetadaten den
Installationsbefehl erneut ausführen.

Das Extra `dev` installiert die in `pyproject.toml` festgelegten Werkzeuge:

- pytest **9.1.1**
- Ruff **0.17.2** für Linting und Formatierung
- mypy **2.4.0** für statische Typprüfung

Ohne Entwicklungswerkzeuge genügt `python -m pip install -e .`.
Installation und Prüfungen erfolgen innerhalb der `.venv`; globale
Paketinstallationen sind nicht erforderlich. Ein vollständiger Lockstand für
transitive Abhängigkeiten steht noch aus.

## Tägliche Nutzung

In einer neuen Shell zuerst in das Service-Verzeichnis wechseln und die
bestehende `.venv` wie oben aktivieren. Nach der Projektinstallation lässt sich
der Paketimport so prüfen:

```bash
python -c "import soly_simulator; print(soly_simulator.__file__)"
```

Die konfigurierten Qualitätsprüfungen werden aus dem Service-Verzeichnis
aufgerufen:

```bash
python -m pytest
python -m ruff check .
python -m ruff format --check .
python -m mypy src
```

Zum automatischen Formatieren `python -m ruff format .` verwenden.
Mit `python -m mypy src tests` können auch die Tests in die Typprüfung
einbezogen werden.

Die virtuelle Umgebung am Ende der Sitzung verlassen:

```bash
deactivate
```

Eine Aktivierung ist optional, wenn der Interpreter direkt aufgerufen wird,
zum Beispiel unter Linux/macOS mit `.venv/bin/python -m pip check` oder unter
Windows mit `.\.venv\Scripts\python.exe -m pip check`.

## Tests mit pytest

Die Tests liegen unter `tests/`. `tests/test_import.py` prüft als Smoke-Test,
dass sich das installierte Paket `soly_simulator` importieren lässt. Die
Konfiguration in `pyproject.toml` verwendet diesen Testordner, den Importmodus
`importlib` sowie strenge Prüfungen für Konfiguration und Marker. Zusätzliche
Python-Suchpfade werden nicht gesetzt; das Projekt muss vorher installiert sein.

Für die gezielte Einrichtung von pytest ohne die übrigen Entwicklungswerkzeuge
in der aktivierten `.venv`:

```bash
python -m pip install -e . "pytest==9.1.1"
python -m pytest
```

Wer bereits `python -m pip install -e ".[dev]"` ausgeführt hat, hat pytest schon
installiert und kann direkt die Tests starten.

Einzelnen Smoke-Test ausführen:

```bash
python -m pytest tests/test_import.py
```

## Linting und Formatierung mit Ruff

Ruff **0.17.2** übernimmt Linting und Formatierung für den Python-Code in
`src/` und `tests/`. Die zentrale Konfiguration steht in `pyproject.toml`:
Python 3.12 als Sprachziel, 88 Zeichen als Zielbreite beim Formatieren und
eine Prüfung der verwendeten Ruff-Version.

Die aktivierten Lint-Regeln prüfen grundlegende Codefehler (`E4`, `E7`, `E9`,
`F`), die Importsortierung (`I`), moderne Python-Schreibweisen (`UP`) und
häufige Fehlerquellen (`B`).

Für die gezielte Installation in der aktivierten `.venv`:

```bash
python -m pip install "ruff==0.17.2"
```

Bei Installation mit `python -m pip install -e ".[dev]"` ist Ruff bereits
enthalten.

Aus dem Service-Verzeichnis prüfen, ohne den Quellcode zu verändern:

```bash
python -m ruff check .
python -m ruff format --check .
```

Beide Befehle berücksichtigen Quellcode und Tests. Die `.venv` sowie die in
`.gitignore` ausgeschlossenen Artefakte werden bei der Verzeichnissuche
übersprungen.

Automatisch korrigierbare Lint-Probleme beheben und anschließend formatieren:

```bash
python -m ruff check --fix .
python -m ruff format .
```

Diese beiden Befehle ändern Dateien. Die Änderungen vor dem Commit prüfen;
verbleibende Lint-Meldungen müssen manuell behoben werden. Die Importsortierung
übernimmt `ruff check --fix`, die Formatierung übernimmt `ruff format`.
