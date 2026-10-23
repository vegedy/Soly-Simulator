# Soly-Simulator

Simulator für PV- und Batterieereignisse der Soly-Pipeline, eingebunden als
Git-Submodule unter `Soly/simulator/`. Bisher sind die Python-Projektgrundlage
und ein Import-Smoke-Test eingerichtet; die Ereignisgenerierung folgt separat.
Docker-Image und CI validieren diesen Ausgangsstand.

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

Anschließend auf allen Plattformen zuerst die vollständigen, mit SHA-256-Hashes
fixierten Entwicklungs- und Buildabhängigkeiten installieren und danach das eigene
Paket editierbar einrichten. Die Installation des Pakets löst keine zusätzlichen
Abhängigkeiten auf und startet keine unkontrollierte Build-Umgebung:

```bash
python -m pip install --require-hashes --only-binary=:all: -r requirements/dev.txt
python -m pip install --no-deps --no-build-isolation -e ".[dev]"
python -m pip check
```

In neuen Shells die vorhandene Umgebung erneut aktivieren; mit `deactivate`
verlassen. `.venv/`, Caches und Build-Artefakte sind über `.gitignore`
ausgeschlossen. Globale Paketinstallationen sind nicht erforderlich.

## Struktur

```text
src/soly_simulator/  Python-Paket
tests/              Import-Smoke-Test und zukünftige Tests
docker/             Container-Smoke-Test
requirements/       Vollständige Lockdateien mit Hashes
.github/workflows/  GitHub-Actions-CI
Dockerfile          Mehrstufiger Paket-Build und Laufzeit-Image
pyproject.toml      Paketmetadaten, Abhängigkeiten und Werkzeugkonfiguration
```

## Prüfungen

In der aktivierten Umgebung:

```bash
python -m pip check              # Abhängigkeitskonsistenz
python -m pytest                 # Tests
python -m ruff check .           # Linting
python -m ruff format --check .  # Formatprüfung
python -m mypy src tests         # Typprüfung von Quellcode und Tests
```

Zum automatischen Formatieren: `python -m ruff format .`.


## Docker

Alle Befehle benötigen nur einen Checkout von **Soly-Simulator**, kein Hauptrepo,
keine lokale Python-Installation und keine `.venv`. Voraussetzung ist eine laufende
Docker Engine. Die geprüfte Zielplattform ist **linux/amd64**; andere Plattformen
sind bisher nicht verifiziert.

```bash
docker build --platform linux/amd64 --tag soly-simulator:local .
docker run --rm --network none --read-only --workdir /tmp soly-simulator:local
```

Der Standardbefehl ist vorerst ein Smoke-Test, kein fachlicher Simulator-Start.
Er prüft mit isoliertem Python (`-I`) die exakte Version **3.12.15**, den Import
von `soly_simulator` aus `site-packages` und die installierten Paketmetadaten.
Es werden keine Verzeichnisse eingebunden; der Test läuft unter einer unprivilegierten
UID außerhalb des Quellbaums und benötigt weder Netzwerk noch Zugangsdaten.
Bei einem Fehler endet der Container mit einem Fehlercode.

Das Basis-Image ist in allen Build-Stufen über Tag und Digest fixiert:

```text
python:3.12.15-slim-bookworm@sha256:6a0e06f5ba0b373d051aabd3fffb9b873f27f9a2a3a14bcbe37dee6f0e3bbc70
```

Der Digest wurde am **23. Oktober 2026** mit `docker pull` ermittelt und auf
`linux/amd64` geprüft. Der Dockerfile baut zunächst mit den festgeschriebenen
Buildwerkzeugen ein Wheel. Das Laufzeit-Image installiert nur dieses Wheel und
die Laufzeitabhängigkeiten; Buildwerkzeuge und Testwerkzeuge werden nicht aus
der Build-Stufe übernommen. `pip check` kontrolliert die Installation im Build.
Die `.dockerignore` lässt ausschließlich die benötigten Paket-, Lizenz-,
Lock- und Smoke-Test-Dateien zu. Git-Metadaten, virtuelle Umgebungen, Caches,
lokale Secrets und generierte Datensätze gelangen dadurch nicht in den Build-Kontext.

## Abhängigkeiten reproduzieren und aktualisieren

`pyproject.toml` enthält die direkten Paketabhängigkeiten sowie pytest **9.1.1**,
Ruff **0.17.2** und mypy **2.4.0**. Die Lockdateien fixieren zusätzlich die
transitiven Abhängigkeiten und erlaubten Download-Hashes:

- `requirements/build.txt`: pip, setuptools, wheel und deren Abhängigkeiten;
  direkte Vorgaben in `requirements/build.in`.
- `requirements/runtime.txt`: Laufzeitabhängigkeiten aus `pyproject.toml`.
  Aktuell ist diese Datei bis auf ihren generierten Header leer, da der Simulator
  noch keine Laufzeitabhängigkeiten hat.
- `requirements/dev.txt`: Build- und Testwerkzeuge einschließlich transitiver
  Abhängigkeiten aus `pyproject.toml` und `requirements/dev.in`.
  Colorama ist auch unter Linux enthalten, damit die pytest-Abhängigkeit für
  Windows im Lockstand erfasst ist.

Bei Installationen werden nur Wheels mit passenden Hashes akzeptiert. Das eigene
Paket wird aus dem jeweiligen Git-Stand gebaut. Ein Lockstand fixiert die externen
Eingaben, garantiert jedoch keine bitweise identischen Docker-Layer oder Wheel-Zeitstempel.

Lockdateien werden bewusst mit **Python 3.12.15** und **pip-tools 7.5.2**
aktualisiert. Dafür eine separate Umgebung anlegen und aktivieren
(`python -m venv .venv-lock`, Aktivierung wie oben), dann:

```bash
python -m pip install "pip-tools==7.5.2"
python -m piptools compile --generate-hashes --allow-unsafe --strip-extras --output-file requirements/build.txt requirements/build.in
python -m piptools compile --generate-hashes --allow-unsafe --strip-extras --output-file requirements/runtime.txt pyproject.toml
python -m piptools compile --generate-hashes --allow-unsafe --strip-extras --extra dev --output-file requirements/dev.txt pyproject.toml requirements/dev.in
```

Bestehende Pins werden dabei beibehalten, soweit sie die Vorgaben erfüllen.
Für gezielte Versionswechsel die Vorgaben ändern und bei Bedarf
`--upgrade-package PAKET` ergänzen. Danach den geänderten Lockstand prüfen,
die Entwicklungsumgebung frisch installieren, alle Prüfungen ausführen und das
Docker-Image erneut bauen. Bei neuen Laufzeitabhängigkeiten beide betreffenden
Lockdateien gemeinsam aktualisieren.

## GitHub Actions

Die CI läuft bei **jedem Push auf jeden Branch** sowie bei **Pull Requests nach
`main`**. Sie installiert Python **3.12.15**, die gehashten Entwicklungsabhängigkeiten
und das eigene Paket mit denselben Befehlen wie lokal. Danach laufen `pip check`,
pytest, Ruff-Linting, Ruff-Formatprüfung und mypy für `src` und `tests`.

**Docker-Build und Container-Smoke-Test laufen ausschließlich bei Pushes auf
`main`**, nachdem alle Python-Prüfungen erfolgreich waren. Auf Arbeitsbranches
und in Pull Requests wird kein Docker-Image gebaut. Ein fehlgeschlagener Build
oder Smoke-Test lässt den Workflow fehlschlagen. Die Actions sind über Commit-IDs
fixiert; der Workflow besitzt nur `contents: read` und benötigt keine Secrets.
Images werden nicht in eine Registry veröffentlicht.
