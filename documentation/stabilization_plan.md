# Stabilization Plan

Stand: 2026-04-09

## Zweck

Dieses Dokument definiert den Arbeitsrahmen fuer die naechsten Schritte in `plangoreminisce`.
Ziel ist kein neues Feature-Push und kein UI-Redesign, sondern ein solider, nachvollziehbarer Stand, auf dem wir anschliessend gezielt weiterentwickeln und parallelisieren koennen.

## Nicht-Ziele

1. Keine direkten UI- oder UX-Aenderungen aus Geschmacksgruenden.
2. Kein vorschnelles Domain- oder Design-Refactoring ohne belegten Nutzen.
3. Keine Datenmigration aus der alten Produktion, bevor Staging und der aktuelle Stand sauber verifiziert sind.
4. Kein Rails-Major-/Minor-Upgrade. Das Projekt laeuft bereits auf Rails `8.1.x`.

## Produktentscheidungen (Stand heute)

1. Der erste Freundes-Test umfasst den gesamten Produktbereich:
   - Planung
   - Memories
   - Expenses
2. Mobile-first ist verbindlich.
3. Kritische mobile Kernfluesse muessen real funktionieren, insbesondere:
   - Upload von Fotos auf dem iPhone
   - alltaegliche Nutzung zentraler Flows auf kleinen Screens
4. Unfertige Bereiche duerfen vorerst sichtbar bleiben.
5. Staging darf echte E-Mails versenden.
6. Produktion bleibt vorerst unangetastet; aktive Arbeit erfolgt zuerst auf Staging.
7. SQLite bleibt die Produktionsdatenbank fuer den aktuellen Stabilisierungspfad.
8. Eine spaetere Migration bestehender Memories/Journals/Attachments ist gewuenscht, wenn sie vertretbar ist.
9. Das Datenmodell darf bei Bedarf noch einmal grundsaetzlich ueberdacht werden; fruehere Entscheidungen gelten nicht als unverrueckbar.

## Definition eines soliden Ausgangsstands

Ein belastbarer Ausgangsstand ist erreicht, wenn folgende Punkte gelten:

1. Die App bootet lokal reproduzierbar ueber die Projekt-Binstubs.
2. Staging ist deploybar, isoliert und dokumentiert.
3. Kernfluesse haben eine kleine, verifizierte Smoke-Abdeckung.
4. Trip-Kontext, Meal Planning und Shopping List verhalten sich fachlich konsistent.
5. Offene technische Schulden und Produktluecken sind sichtbar dokumentiert, nicht nur implizit im Code versteckt.

## Aktuelle Risiken

### 1. Fachliche Inkonsistenz zwischen altem und neuem Meal-Planning-Ansatz

- Meal Plans sind inzwischen echte Datensaetze.
- Gleichzeitig existiert noch alter Rezeptstatus ueber `selected_for_shopping`.
- Beispiele:
  - [recipes_controller.rb](/home/leo/dev/projects/plangoreminisce/app/controllers/recipes_controller.rb)
  - [recipe.rb](/home/leo/dev/projects/plangoreminisce/app/models/recipe.rb)
  - [shopping_lists_controller.rb](/home/leo/dev/projects/plangoreminisce/app/controllers/shopping_lists_controller.rb)
  - [plans/shopping.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/plans/shopping.html.erb)

Folge:
- Das Produktmodell ist nicht eindeutig.
- Teile der App sprechen noch die Sprache des alten MVPs, obwohl die aktuelle Richtung Meal Calendar plus abgeleitete Shopping List ist.

### 2. Unvollstaendige oder irrefuehrende Bereiche

- `Plans#packing`, `Plans#itinerary`, `Plans#templates` sind Platzhalter:
  - [plans_controller.rb](/home/leo/dev/projects/plangoreminisce/app/controllers/plans_controller.rb)
- `Memories#albums` ist ebenfalls Platzhalter:
  - [memories_controller.rb](/home/leo/dev/projects/plangoreminisce/app/controllers/memories_controller.rb)
- Trip-Template-Kopie ist nur teilweise umgesetzt:
  - [trips_controller.rb](/home/leo/dev/projects/plangoreminisce/app/controllers/trips_controller.rb)

Folge:
- Produktumfang wirkt weiter als er technisch abgesichert ist.
- Vor einem externen Alltagstest muessen wir klar trennen zwischen tragfaehig und nur angedeutet, auch wenn Bereiche vorerst sichtbar bleiben.

### 3. Testabdeckung ist fuer die Breite der App noch zu duenn

Vorhanden:
- einige Controller-Tests
- wenige Modelltests
- ein Systemtest fuer Meal Planning
- ein aelterer Integrationstest

Nicht ausreichend abgesichert sind derzeit mindestens:
- Einladungsflow
- Registrierung/Login-Varianten
- Expense-Flow
- Diskussionen
- Journal/Memories mit Trip-Kontext
- Rezeptbibliothek vs. Trip-Rezepte
- mobile Foto-Uploads und mobile Medienfluesse

### 4. Dokumentation war historisch ueberoptimistisch

Die neueren Basisdokumente sind aktueller:
- [status_quo.md](/home/leo/dev/projects/plangoreminisce/documentation/status_quo.md)
- [testing.md](/home/leo/dev/projects/plangoreminisce/documentation/testing.md)

Aber aeltere Doku beschreibt den Stand teilweise zu positiv oder zu alt:
- [documentation/README.md](/home/leo/dev/projects/plangoreminisce/documentation/README.md)
- [plangoreminisce-architecture.md](/home/leo/dev/projects/plangoreminisce/documentation/plangoreminisce-architecture.md)

## Arbeitsstraenge

### A. Runtime, Deploy und Betriebsfaehigkeit

Ziel:
- Lokale Arbeit, Tests und Deploys muessen reproduzierbar sein.

Aufgaben:
1. Projekt-Binstubs als Standardweg etablieren.
2. Staging deployen und Basisfunktion verifizieren.
3. Staging-Secrets und Mail-/Host-Verhalten dokumentieren.
4. Backup-Strategie fuer bestehende Produktion festhalten, bevor Migrationsthemen beginnen.

Done-Kriterien:
1. `bin/rails`, `bin/rake`, `bin/setup` funktionieren auf dem Entwicklerrechner verlässlich.
2. `bin/kamal deploy -d staging` ist dokumentiert und praktisch durchfuehrbar.
3. Staging ist klar von Produktion isoliert.
4. Staging kann mit echtem Mailversand betrieben werden.

### B. Fachliche Konsolidierung von Trip-Kontext, Meal Plan und Shopping

Ziel:
- Ein eindeutiges fachliches Modell ohne parallele alte und neue Logikpfade.

Aufgaben:
1. Entscheiden, ob `selected_for_shopping` noch temporär benoetigt wird oder entfernt werden soll.
2. Alte Benennungen wie `generate_from_recipes` gegen fachlich passende Namen konsolidieren.
3. Pruefen, welche Screens noch altes Wording oder alte Erwartungen tragen.
4. Konsistente Regeln fuer `current_trip` und context-based routing festlegen.
5. Pruefen, ob das Datenmodell fuer Planung insgesamt tragfaehig ist oder neu geschnitten werden sollte.

Done-Kriterien:
1. Meal Planning ist die eindeutige Quelle fuer geplante Mahlzeiten.
2. Shopping List Generation basiert nachvollziehbar auf dem gewaehlten Zielmodell.
3. Es existieren keine irrefuehrenden Altpfade mehr, die stillschweigend anderes Verhalten suggerieren.

### C. Test- und Release-Gate

Ziel:
- Ein kleiner, ehrlicher Testkorridor statt einer breiten, fragilen Scheinsicherheit.

Aufgaben:
1. Vorhandene Controller-Tests weiter von direkter Session-Manipulation wegziehen.
2. Einen minimalen Smoke-Korridor definieren.
3. Fuer kritische Flows gezielt Playwright-E2E oder Rails-Systemtests einsetzen.
4. Festlegen, welche Tests vor jedem Staging-Deploy gruen sein muessen.
5. Mobile Kernfluesse explizit pruefen, nicht nur Desktop-Browser.

Minimaler Smoke-Korridor:
1. Login
2. Trip wechseln
3. Trip anlegen
4. Rezept anlegen
5. Meal einplanen
6. Shopping List aus Meal Plan erzeugen
7. Expense anlegen
8. Einladung aufrufen und annehmen oder sauber abweisen
9. Foto-Upload auf mobilem Safari bzw. iPhone-vergleichbarer Umgebung

Done-Kriterien:
1. Der minimale Smoke-Korridor ist automatisiert oder klar reproduzierbar dokumentiert.
2. Ein Staging-Deploy erfolgt nicht mehr ohne diesen Korridor.

### D. Dokumentation und Entscheidungslog

Ziel:
- Kuenftige Arbeit darf nicht wieder an implizitem Projektwissen haengen.

Aufgaben:
1. Dieses Dokument als operatives Referenzdokument pflegen.
2. `documentation/README.md` auf die tatsaechlichen Kern-Dokumente reduzieren.
3. Architektur- und Statusdokumente auf Konsistenz pruefen.
4. Wichtige fachliche Entscheidungen in einem knappen Entscheidungslog festhalten.

Done-Kriterien:
1. Neue Arbeitspakete lassen sich gegen dieses Dokument mappen.
2. Veraltete Aussagen sind entweder entfernt oder klar als historisch markiert.

### E. Produktluecken vor externem Testbetrieb

Ziel:
- Kein Vollausbau, sondern bewusste Freigabe dessen, was fuer einen Freundes-Test tragfaehig ist.

Aufgaben:
1. Bereich fuer Bereich in `must / should / could` einordnen.
2. Platzhalter-Funktionen und halbfertige Pfade erfassen.
3. Vor dem Testbetrieb klar definieren, was offiziell unterstuetzt ist.
4. Innerhalb jedes Bereichs nur die Funktionen absichern, die fuer echte Trips relevant sind; nicht jeder Trip braucht jede Planungsfunktion.

Done-Kriterien:
1. Es gibt eine explizite Beta-Scope-Liste.
2. Die App enthaelt fuer den Testzeitraum keine versteckten Kernbrueche in den aktiv genutzten Flows.

### F. Produktionsdaten und Migration

Ziel:
- Alte MVP-Daten sichern und spaeter kontrolliert in die neue Struktur ueberfuehren.

Aufgaben:
1. Produktionsbackup der SQLite-Datenbank und Active-Storage-Dateien erstellen.
2. Altes Produktionsschema gegen aktuelles Schema vergleichen.
3. Migrierbare Datenklassen festlegen.
4. Migrationsregeln dokumentieren, bevor Code geschrieben wird.

Wahrscheinlich migrierbar:
1. Users
2. Trips
3. Journal entries / memories
4. Attachments
5. Invitations, falls semantisch noch passend

Unsicher:
1. Alte Shopping-Listen-Strukturen
2. Alte Meal-/Recipe-Auswahlzustaende
3. Historische Session- oder derivebare Kontextdaten

Done-Kriterien:
1. Es existiert ein schriftlicher Migrationsplan vor jeder echten Datenuebernahme.
2. Produktion bleibt bis zur finalen Entscheidung unveraendert.

## Empfohlene Reihenfolge

### Phase 1: Stabilisieren

1. Runtime/Deploy absichern
2. Testkorridor definieren
3. Meal Plan und Shopping fachlich konsolidieren

### Phase 2: Scope schaerfen

1. Platzhalter- und Halbfeatures inventarisieren
2. Beta-Scope fuer externen Test festlegen
3. Doku auf den realen Stand bringen

### Phase 3: Migration vorbereiten

1. Produktionsdaten sichern
2. Schemas vergleichen
3. Migrationsplan schreiben

## Parallelisierungsvorschlag

Diese Arbeit laesst sich spaeter sinnvoll in getrennte Pakete aufteilen:

1. `ops`
   - staging deploy
   - secrets
   - backup runbook

2. `domain-consistency`
   - meal planning
   - shopping list generation
   - trip context cleanup

3. `test-gate`
   - smoke tests
   - Playwright flows
   - Controller-Testbereinigung

4. `documentation`
   - docs index
   - status updates
   - decision log

5. `migration-discovery`
   - production schema audit
   - data mapping
   - import strategy

## Offene Fragen

Diese Fragen blockieren nicht sofort, sollten aber vor tieferer Umsetzung beantwortet oder weiter geschaerft werden:

1. Was genau soll mit `selected_for_shopping` passieren?
   Aktueller Stand:
   - Das Feld stammt aus einem aelteren Ansatz, bei dem Rezepte direkt fuer Shopping markiert wurden.
   - Der neue fachliche Kurs zeigt eher in Richtung Meal Plan als Quelle fuer Einkaufslisten.
   Entscheidung noch offen:
   - entfernen
   - nur temporaer als Kompatibilitaetsfeld behalten
2. Soll das Planungsmodell langfristig widget-/bausteinbasiert werden, sodass pro Trip nur relevante Planungsfunktionen aktiv sind?
3. Welche Bereiche des heutigen Datenmodells gelten als stabil, und welche duerfen im Zuge der Konsolidierung noch neu gedacht werden?

## Arbeitsregel fuer die naechsten Schritte

Bis auf Weiteres gilt:

1. Stabilitaet vor Feature-Ausbau.
2. Keine UI-/UX-Aenderungen ohne eigene Designrunde.
3. Kleine thematische Commits statt Sammelcommits.
4. Jede groessere Aenderung soll gegen dieses Dokument begruendet werden koennen.
