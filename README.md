# Soly-Simulator

Simulator für PV- und Batterieereignisse der Soly-Pipeline, eingebunden als
Git-Submodule unter `Soly/simulator/`. Bisher sind die Python-Projektgrundlage
und ein Import-Smoke-Test eingerichtet; die Ereignisgenerierung folgt separat.
Docker-Image und CI validieren diesen Ausgangsstand.

## Entwicklungsbefehle

Voraussetzung: **Python 3.12.15**. `dev.sh` (POSIX-Shell unter Unix) und `dev.ps1`
(Windows PowerShell 5.1 oder PowerShell 7) delegieren an `scripts/dev.py` mit
Python-Standardbibliothek. Jeder Checkout besitzt eine eigene `.venv`; Aktivierung
ist unnötig. Die Befehle bestimmen den Repository-Pfad selbst. Auch ein Aufruf aus
einem anderen Verzeichnis oder ein Checkout-Pfad mit Leerzeichen funktioniert:

```bash
"/pfad mit Leerzeichen/Soly-Simulator/dev.sh" setup
"/pfad mit Leerzeichen/Soly-Simulator/dev.sh" check
```

Im Repository unter Unix:

```bash
./dev.sh setup
./dev.sh check
./dev.sh format
```

Unter Windows PowerShell (mit vorhandenem Python 3.12.15):

```powershell
.\dev.ps1 setup
.\dev.ps1 check
.\dev.ps1 format
# Aus einem anderen Verzeichnis:
& 'C:\Projekte mit Leerzeichen\Soly-Simulator\dev.ps1' check
```

| Befehl | Wirkung |
|---|---|
| `setup` | Erstellt oder verwendet `.venv`, installiert vorhandene Hash-Locks und prüft Abhängigkeiten. Erneut ausführbar; keine Lock-Neuauflösung. |
| `check` | `pip check`, pytest, Ruff-Linting, Ruff-Formatprüfung und mypy einschließlich `scripts/`; stoppt beim ersten Fehler. |
| `format` | Schreibt ausdrücklich Ruff-Formatänderungen in Projektdateien. |
| `docker-smoke` | Baut `linux/amd64` als `soly-simulator:dev-smoke` und führt den vorhandenen isolierten Container-Smoke-Test aus. |

`check` formatiert keine Dateien und legt Tool-Caches/Bytecode nicht im Checkout
an. Externe Fehlercodes werden weitergegeben. Kein Befehl aktualisiert Submodule,
löscht lokale Daten oder verändert globale Systemeinstellungen.

`docker-smoke` überspringt die lokale `.venv` und verwendet einen Host-Interpreter;
`SOLY_PYTHON` bleibt als ausdrückliche Vorgabe vorrangig.

Interpreterwahl: `SOLY_PYTHON` (ein vollständiger Dateipfad, keine zusätzlichen
Argumente), vorhandene `.venv`, dann `python3.12`/`python3`/`python` unter Unix;
PowerShell versucht vor den Python-Befehlen zusätzlich `py -3.12`. Eine ungeeignete
Python-Version oder unvollständige `.venv` führt zu einem Hinweis, nicht zum
Löschen/Ersetzen. Bei Bedarf die vorhandene Umgebung zuerst selbst prüfen und
beiseitelegen. Einen bestimmten Interpreter auswählen:

```bash
SOLY_PYTHON='/pfad zu Python/bin/python3.12' ./dev.sh setup
```

```powershell
$env:SOLY_PYTHON = 'C:\Pfad zu Python\python.exe'
.\dev.ps1 setup
```


**Windows-Weg:** Mit den bestehenden Pins zunächst **WSL2** und die Unix-Befehle
in einem Linux-Checkout verwenden. `actions/setup-python` konnte Python 3.12.15
auf Windows 2025 nicht bereitstellen. Der native PowerShell-Einstieg setzt einen
selbst bereitgestellten Python-3.12.15-Interpreter voraus (`SOLY_PYTHON`); dieser
native Installationsweg und Windows PowerShell 5.1 sind bislang nicht verifiziert.
Es wird nicht automatisch auf eine andere Python-Version ausgewichen.

Falls die lokale PowerShell-Richtlinie Skripte sperrt, die geltende Richtlinie
prüfen oder den Python-Einstieg direkt aufrufen; die Skripte ändern keine
Sicherheitseinstellungen und verwenden keinen Execution-Policy-Bypass:

```powershell
py -3.12 scripts/dev.py setup
& .\.venv\Scripts\python.exe scripts/dev.py check
```

Die CI nutzt `setup --use-current-python` und `check --use-current-python` mit dem
bereits durch Actions eingerichteten Python. Lokal erlaubt `setup` diese Option
nur in einer virtuellen Umgebung; außerhalb davon ist sie ausschließlich mit
`CI=true` vorgesehen. Normalerweise ohne diese Option arbeiten. Die Skripte und
Textdateien verwenden festgelegte Zeilenenden; Vertragsartefakte behalten über
`.gitattributes` ihre exakten Bytes.

`setup` installiert `requirements/dev.txt` mit
`--require-hashes --only-binary=:all:`, danach das eigene Paket editierbar mit
`--no-deps --no-build-isolation -e ".[dev]"`. Das Paket löst keine weiteren
Abhängigkeiten auf. `.venv/`, Caches und Build-Artefakte bleiben ignoriert.

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

## Docker

Alle Befehle benötigen nur einen Checkout von **Soly-Simulator**, kein Hauptrepo,
keine `.venv`. Der Wrapper benötigt einen Python-Interpreter (empfohlen 3.12.15);
Voraussetzung ist eine laufende
Docker Engine. Die geprüfte Zielplattform ist **linux/amd64**; andere Plattformen
sind bisher nicht verifiziert.

```bash
./dev.sh docker-smoke
# PowerShell: .\dev.ps1 docker-smoke
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
(`python -m venv .venv-lock`, unter Unix `source .venv-lock/bin/activate`, unter Windows `.\.venv-lock\Scripts\Activate.ps1`), dann:

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
und das eigene Paket über `setup --use-current-python`. Danach führt
`check --use-current-python` dieselben Prüfungen wie lokal aus, einschließlich
der Typprüfung von `src`, `tests` und `scripts`. Die Python-Jobs laufen unter
Ubuntu 24.04 mit `dev.sh` und PowerShell 7 über `dev.ps1`, jeweils in einem
Checkout-Pfad mit Leerzeichen. Der Windows-Runner konnte Python 3.12.15 über
`actions/setup-python` nicht bereitstellen; die Laufzeitpins bleiben unverändert.

**Docker-Build und Container-Smoke-Test laufen ausschließlich bei Pushes auf
`main`**, nachdem alle Python-Prüfungen erfolgreich waren. Auf Arbeitsbranches
und in Pull Requests wird kein Docker-Image gebaut. Ein fehlgeschlagener Build
oder Smoke-Test über `./dev.sh docker-smoke` lässt den Workflow fehlschlagen. Die Actions sind über Commit-IDs
fixiert; der Workflow besitzt nur `contents: read` und benötigt keine Secrets.
Images werden nicht in eine Registry veröffentlicht.


## Validierung von SOLY-18

Am **3. November 2026** unter **Linux x86_64**, Python **3.12.15** und
**PowerShell 7.5.4** tatsächlich ausgeführt: frischer eigenständiger Checkout in
einem Pfad mit Leerzeichen, `setup` über Unix und PowerShell erneut ausgeführt,
`check` und `format` über beide Einstiege, außerdem `setup/check` mit
`--use-current-python`. Alle Prüfungen erfolgreich (**15 Tests**, pip check,
Ruff und mypy). Dateiinhalt und Änderungszeit der Projektdateien blieben bei
beiden `check`-Aufrufen unverändert. Fehlercodes, unvollständige Umgebungen,
fehlende Werkzeuge und Plattformhinweise sind zusätzlich durch Regressionstests
abgedeckt. `./dev.sh docker-smoke` wurde auf **linux/amd64** erfolgreich ausgeführt.
Locks, Laufzeitpins und der bestehende Container-Smoke-Test wurden nicht geändert.

Native Windows-Ausführung konnte in der CI auf **windows-2025** nicht
geprüft werden: `actions/setup-python` stellt dort Python 3.12.15 nicht bereit.
Die endgültige CI prüft daher Unix und PowerShell 7 unter Ubuntu 24.04.
Windows PowerShell 5.1 und macOS wurden nicht ausgeführt. Ein PowerShell-Test
unter Linux ist kein nativer Windows-Nachweis.

## Unterstützter Ereignisvertrag

Dieser Service unterstützt **Soly event contract v1**.

Erzeugt Rohmessungen mit unveränderten Zustandsstrings, Quellzeit und ausdrücklicher Snapshot-/Änderungskennzeichnung.
Diese Rolle beschreibt die vorgesehene Schnittstelle; die fachliche
Service-Implementierung und Laufzeitvalidierung folgen in eigenen Issues.

Die [maßgebliche Spezifikation](https://github.com/vegedy/Soly/blob/abd467e82f1bf57279ae3c14a01a765389daad90/docs/data-contract.md)
ist auf einen unveränderlichen, veröffentlichten Hauptrepo-Commit festgeschrieben.
[contracts/v1/](contracts/v1/) enthält eine identische lokale Kopie aller Schemata,
des Sensorkatalogs und der synthetischen Beispiele. Der eigenständige Checkout
benötigt dafür weder das Hauptrepo noch benachbarte Services.
[contracts/provenance.json](contracts/provenance.json) nennt unterstützte Version,
Herkunftsrepository, vollständigen Commit und SHA-256-Prüfsummen aller Dateien.
Es gibt keine Schema-Downloads beim Start und keine Laufzeitimporte aus Submodulen.

Veröffentlichte v1-Artefakte bleiben unverändert. Änderungen am Vertragsverhalten
benötigen eine neue Version; unbekannte Versionen werden künftig ausdrücklich
abgelehnt. Eine Vertragsaktualisierung übernimmt alle Artefakte und das
Herkunftsmanifest gemeinsam und wird mit den zentralen Vertragsprüfungen geprüft.
Der abschließende Hauptrepo-CI-Lauf kontrolliert die Kopie und ihre Herkunft.

## Mitarbeit und Arbeitsregeln

[AGENTS.md](AGENTS.md) enthält die kurzen Arbeitsregeln für diesen eigenständigen
Service. Die zentrale [Beitragsanleitung](https://github.com/vegedy/Soly/blob/main/CONTRIBUTING.md)
und der [Git-Workflow](https://github.com/vegedy/Soly/blob/main/Soly-Issue-und-Git-Workflow.md)
erklären Issues, SOLY-Branches, Service-PRs und die anschließende Submodule-Integration.
Die [Technologieentscheidungen](https://github.com/vegedy/Soly/blob/main/Soly-Technologieentscheidungen.md)
unterscheiden historische Auswahl und implementierten Stand.

Die CI prüft zusätzlich den lokalen Setup-Weg in einem frischen Checkout mit
Leerzeichen: Unix-Setup, erneutes PowerShell-Setup mit Erhalt der bestehenden
`.venv`, danach `check` über beide Einstiege ohne `--use-current-python`.
Alle Aufrufe dieses Jobs erfolgen außerhalb des Checkout-Verzeichnisses.
