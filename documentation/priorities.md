# Priorities

Stand: 2026-04-09

Dieses Dokument leitet aus `stabilization_plan.md` eine konkrete Arbeitsreihenfolge ab.
Ziel ist ein belastbarer Stand fuer Staging und einen ersten echten Freundes-Test.

## Arbeitsprinzip

1. Zuerst die Architektur- und Konsistenzthemen schliessen, die viele andere Arbeiten beeinflussen.
2. Danach die fehlende Test-Coverage auf die echten Kernfluesse ausrichten.
3. Erst wenn dieser Sockel steht, lohnt sich breitere Parallelisierung.

## Must

Diese Punkte sind Pflicht vor einem belastbaren Staging-Stand.

### 1. Meal Planning und Shopping fachlich konsolidieren

Warum:
- Hier liegt aktuell die groesste Inkonsistenz.
- Alte und neue Logik existieren parallel.
- Viele weitere Tests und Reviews haengen von einem klaren Zielmodell ab.

Konkret:
1. `selected_for_shopping` aus Modell, Controller, Views, Migration-Folgen und Tests entfernen.
2. `generate_from_recipes` fachlich in eine Meal-Plan-basierte Benennung ueberfuehren.
3. Screens und Helper auf altes Wording und alte Erwartungen pruefen.
4. Klar definieren, welche Entitaet die Quelle der Einkaufslogik ist.

### 2. Test-Coverage fuer Kernfluesse aufbauen

Warum:
- Das ist aktuell der wichtigste Qualitaetshebel.
- Ohne diese Abdeckung ist Staging nur ein manuelles Bauchgefuehl.

Pflichtabdeckung:
1. Login / Session / Trip context switching
2. Einladung aufrufen und sauber weiterfuehren
3. Trip erstellen
4. Rezept erstellen
5. Meal planen
6. Shopping List aus Meal Plan erzeugen
7. Expense anlegen und bearbeiten
8. Memories-Basisfluss mit Trip-Kontext
9. Mobile Foto-Upload mindestens als dokumentierter/verifizierter Testfall

Empfohlene Verteilung:
1. Controller-/Modeltests fuer Logik und Zugriffsregeln
2. Rails-Systemtests fuer kritische Browserfluesse
3. Playwright fuer wenige echte End-to-End-Smokes

### 3. Staging einmal real deployen und pruefen

Warum:
- Der Deploy-Pfad muss praktisch validiert sein, nicht nur theoretisch dokumentiert.

Konkret:
1. Staging deployen
2. Host, Mail, Assets, Storage, Sessions pruefen
3. Smoke-Korridor gegen Staging laufen lassen oder nachvollziehbar manuell pruefen

### 4. Mobile-First-Kernfluesse absichern

Warum:
- Der erste reale Test findet nicht primär auf Desktop statt.
- Das iPhone-Upload-Problem ist ein bekannter historischer Bruch.

Pflichtfokus:
1. Foto-Upload
2. Trip-Wechsel / Navigation
3. Meal Planning
4. Expense-Erfassung

## Should

Diese Punkte sollten vor dem Freundes-Test nachgezogen werden, sind aber nach den `Must`-Themen.

### 1. Platzhalter- und Halbfeatures inventarisieren

Konkret:
1. `packing`
2. `itinerary`
3. `templates`
4. `memories/albums`
5. alte oder leere Views wie `expenses/show`, einige `journal_entries/*`

Ziel:
- nicht sofort alles bauen
- aber jede sichtbare Luecke bewusst erfassen

### 2. Testbestand weiter bereinigen

Konkret:
1. direkte Session-Manipulation in alten Tests entfernen
2. alte Integrations- und Systemtests auf aktuelle Navigation ausrichten
3. test helper und factories/fixtures konsistenter machen

### 3. Dokumentierte Beta-Scope-Liste

Ziel:
- explizit festhalten, welche Features fuer den Test als tragfaehig gelten
- welche nur sichtbar, aber nicht ernsthaft freigegeben sind

### 4. Datenmodell-Review fuer Planung

Warum:
- Du hast selbst gesagt, dass hier viel probiert wurde.
- Vor grosser Weiterentwicklung sollte geprueft werden, ob das Modell die Richtung noch sauber traegt.

## Could

Diese Punkte sind sinnvoll, aber nicht noetig fuer den naechsten stabilen Sockel.

1. Produktionsmigration vorbereiten
2. Langfristigen widget-/bausteinbasierten Planungsansatz ausarbeiten
3. groesseren Architekturtext weiter modernisieren
4. tieferen Decision Log aufbauen
5. SQLite->Postgres-Szenario beschreiben, ohne es jetzt umzusetzen

## Empfehlung zur Arbeitsorganisation

### Zuerst eher sequentiell

Die naechsten Schritte sollten nicht sofort breit parallelisiert werden.
Grund:
- Meal Planning / Shopping / Trip-Kontext ist derzeit ein gemeinsamer Kern.
- Wenn man dort gleichzeitig an Modell, Routing, Benennung und Tests arbeitet, erzeugt das eher Reibung als Geschwindigkeit.

Ich empfehle deshalb zuerst einen sequentiellen Kernblock:

1. fachliches Zielmodell Meal Planning / Shopping bereinigen
2. daraus die erste Welle fehlender Tests schreiben
3. dann Staging deployen und gegen den neuen Sockel pruefen

### Danach gut parallelisierbar

Sobald der Kern stabil ist, kann man gut parallel schneiden:

1. `core-domain`
   - Meal Planning
   - Shopping generation
   - Trip context

2. `coverage`
   - invitations
   - expenses
   - memories
   - mobile/system/browser tests

3. `ops`
   - staging
   - backups
   - production migration discovery

4. `docs`
   - decision log
   - beta scope
   - release checklist

## Konkrete Reihenfolge

### Block A
1. Legacy-Shopping-Logik entfernen
2. Naming und Routen bereinigen
3. zugehoerige Tests aktualisieren

### Block B
1. Memories-Tests modernisieren
2. Expenses-Tests auf Kontext und Kernfluesse pruefen
3. Einladungs-/Auth-Coverage ergaenzen

### Block C
1. kleine Playwright-Smoke-Suite definieren
2. mobile kritische Flows pruefen
3. Staging deployen

### Block D
1. Beta-Scope dokumentieren
2. Platzhalter-Features inventarisieren
3. Produktionsdaten-Migration vorbereiten

## Definition von fertig

Ein erster stabiler Stand ist erreicht, wenn:

1. `selected_for_shopping` und aehnliche Altpfade entfernt sind
2. die Kernfluesse automatisiert abgesichert sind
3. Staging erfolgreich laeuft
4. mobile Kernfluesse kein bekannter Blocker mehr sind
5. wir eine ehrliche Beta-Scope-Liste haben
