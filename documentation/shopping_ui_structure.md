# Shopping UI Structure

Stand: 2026-04-10

## Zweck

Dieses Dokument beschreibt die UI-Struktur fuer den finalen Shopping- und Meal-Planning-Flow.

Es ist kein visuelles Pixel-Spec.
Es legt fest:

1. welche Screens es gibt
2. in welcher Reihenfolge Nutzer durch den Prozess gehen
3. welche Informationen pro Screen im Vordergrund stehen
4. wie die von dir gelieferten Mockups in die Produktstruktur uebersetzt werden

## Grundsatz

Die UI soll den realen Ablauf abbilden:

1. `Meal Plan`
2. `Shopping Plan`
3. `Shopping List`

Das entspricht dem echten Prozess:

1. erst planen wir Mahlzeiten
2. dann organisieren wir daraus den Einkaufsbedarf
3. dann kaufen wir konkret ein

## Top Navigation

In der bestehenden oberen Bereichsstruktur sollen diese drei Tabs oder Segmente existieren:

1. `Meal Plan`
2. `Shopping Plan`
3. `Shopping List`

### Bedeutung

1. `Meal Plan`
   - Planung von Tagen, Mahlzeiten, Rezepten, Portionen
2. `Shopping Plan`
   - Pflegeansicht fuer Bedarfe, Synchronisierung, Splits, Zuordnung auf Listen
3. `Shopping List`
   - operative Einkaufsansicht fuer eine konkrete Liste wie `Aldi` oder `Wochenmarkt`

## Screen 1 - Meal Plan

### Ziel

Der Screen dient dem Planen und Verstehen.

### Primaere Aufgaben

1. Tage und Meals sehen
2. Rezepte zuordnen
3. Portionen anpassen
4. spaeter Verantwortlichkeiten sehen oder pflegen
5. benoetigte Zutaten pro Mahlzeit nachvollziehen

### Wichtige UI-Merkmale

Aus deinem Mockup wird fuer diesen Screen uebernommen:

1. horizontale Tagesnavigation
2. klare Karten pro Meal
3. Portionen direkt in der Karte
4. Zutatenliste direkt unter dem Meal
5. klarer Status, ob ein Meal bereits in den Shopping-Plan uebernommen wurde

### Nicht Ziel dieses Screens

1. kein operatives Einkaufen
2. keine komplexe Listenverteilung
3. keine dauernd sichtbaren Kommentare

## Screen 2 - Shopping Plan

### Ziel

Der Screen dient dem Organisieren des Einkaufsbedarfs.

### Primaere Aufgaben

1. Requirements aus Meals sehen
2. manuelle Requirements hinzufuegen
3. Sync-Status sehen
4. veraltete Requirements erkennen
5. auf konkrete Einkaufslisten verteilen
6. Requirements auf mehrere Listen splitten

### Struktur

Der Screen arbeitet nicht auf abhakbaren Einkaufspositionen, sondern auf Requirements.

Eine Requirement-Zeile oder Karte sollte zeigen:

1. Artikelname
2. benoetigte Gesamtmenge
3. Einheit
4. Kategorie
5. Herkunft
   - Meal oder manuell
6. Sync-Status
7. bereits verteilte Mengen
8. noch unverteilte Mengen

### Sekundaere Aktionen

1. `Synchronize`
2. `Undo last sync`
3. `Add manual requirement`
4. `Split to list`
5. `Move all to list`
6. `Detach from meal plan`

### Kommentarverhalten

Kommentare sind hier nicht primaer sichtbar.
Wenn es spaeter Kommentare zu zugeordneten Positionen gibt, reicht in dieser Ansicht ein kleiner Indikator.

## Screen 3 - Shopping List

### Ziel

Der Screen dient dem echten Einkaufen.

### Primaere Aufgaben

1. konkrete Liste waehlen
2. schnell Positionen sehen
3. Teilmengen kaufen
4. Fortschritt erfassen
5. Kommentare bei Bedarf aufklappen

### Struktur

Die Ansicht arbeitet auf `ShoppingListAssignment`.

Oben soll klar sein:

1. welche Liste offen ist
2. wie viele Positionen offen / teilweise / erledigt sind
3. optional Such- und Filteraktionen

Die Hauptliste soll zeigen:

1. Kategorie-Sektionen
2. pro Position:
   - Name
   - geplante Menge
   - gekaufte Menge
   - verbleibende Menge
   - Herkunfts-Tags
   - Kommentar-Indikator

### Kommentarverhalten

Kommentare sollen nicht standardmaessig aufgeklappt sein.

Regel:

1. nur ein Icon oder kleiner Counter zeigt an, dass Kommentare existieren
2. der Inhalt erscheint erst nach Detail-Expand

Das passt zu deinem Mockup und vermeidet visuelle Ueberladung im Standardfall.

## Ableitung aus deinen Mockups

### Screenshot Einkaufsliste

Folgende Elemente werden direkt als Richtung uebernommen:

1. mobile-first Verdichtung
2. Kategorie-Sektionen
3. Fortschrittsanzeige pro Position
4. Herkunfts-Tags bei Positionen
5. klare offene/erledigte Logik
6. Kommentar-Indikator an Positionen

Nicht 1:1 festgelegt, aber als Richtung gesetzt:

1. weiche Segmentsteuerung oben
2. kompakte Statuszeile
3. schnelle Bedienbarkeit mit einer Hand

### Screenshot Meal Plan

Folgende Elemente werden direkt als Richtung uebernommen:

1. Tagesnavigation oben
2. Meal-Karten mit Zutatenueberblick
3. Portionensteuerung direkt im Kontext
4. klarer Status zwischen Meal Plan und Shopping

## Informationshierarchie

### Meal Plan

Reihenfolge der Aufmerksamkeit:

1. Tag
2. Meal
3. Rezept / freier Eintrag
4. Portionen
5. Zutaten
6. Uebernahmestatus in den Shopping-Plan

### Shopping Plan

Reihenfolge der Aufmerksamkeit:

1. Requirement
2. Menge
3. Herkunft
4. Sync-Status
5. Verteilung auf Listen
6. manuelle Aktionen

### Shopping List

Reihenfolge der Aufmerksamkeit:

1. Kategorie
2. Artikel
3. offene Restmenge
4. Fortschritt
5. Kommentar-Indikator
6. Detail-Expand

## Mobile Leitlinien

1. jeder Screen muss ohne horizontales Layout-Chaos funktionieren
2. primaere Aktionen muessen im Daumenbereich erreichbar sein
3. Standardansicht darf nicht von offenen Formularen ueberladen werden
4. Details gehen in Expand, Drawer oder Sekundaeransichten
5. Shopping List hat hoehere Informationsdichte als der aktuelle Stand

## Konsequenzen fuer die Implementierung

1. Wir bauen nicht zuerst die bisherige `Shopping List`-Seite weiter aus.
2. Wir bauen zuerst das neue Modell und richten die Screens konsequent an den drei Tabs aus.
3. `Meal Plan`, `Shopping Plan` und `Shopping List` werden als zusammenhaengender Prozess verstanden.
4. Kommentare werden technisch frueh mitgedacht, aber im UI standardmaessig nur indikativ gezeigt.

## Was fuer die Implementierung jetzt ausreichend klar ist

1. die Screen-Aufteilung
2. die Reihenfolge der Nutzung
3. die grobe Informationsarchitektur
4. die Rolle der Kommentare
5. die mobile Priorisierung

Ein spaeteres visuelles Feintuning bleibt moeglich, ohne das Modell erneut umzubauen.
