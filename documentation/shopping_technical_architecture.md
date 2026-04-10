# Shopping Technical Architecture

Stand: 2026-04-10

## Ziel

Dieses Dokument uebersetzt das fachliche Konzept aus [shopping_workflow_concept.md](./shopping_workflow_concept.md) in eine technische Zielarchitektur.

Es beschreibt:

1. das finale Datenmodell
2. die Grenzen zwischen `Meal Planning` und `Shopping`
3. die Synchronisierungslogik
4. den Umgang mit Einheiten, Aggregation und Splits
5. die Umsetzungsphasen

Das Dokument ist bewusst zielorientiert.
Es beschreibt nicht, wie der aktuelle Code funktioniert, sondern wie die finale Loesung gebaut werden soll.

## Architekturprinzipien

1. `Meal Planning` und `Shopping` sind getrennte Domaenen.
2. `Shopping` ist eine eigene Arbeitsdomaene und kein Nebenprodukt des Meal Plans.
3. Anforderungen aus dem Meal Plan werden als Bedarf modelliert, nicht direkt als Einkaufslistenzeilen.
4. Konkrete Einkaufslisten sind nur Auspraegungen eines Bedarfs fuer einen Einkaufskontext wie `Aldi` oder `Wochenmarkt`.
5. Synchronisierung ist explizit, nachvollziehbar und rueckgaengig.
6. UX hat Vorrang vor Ruecksicht auf bestehende Shopping-Implementierungen.

## Domaenenmodell

### 1. MealPlan

`MealPlan` bleibt die Planungseinheit fuer:

1. Tag
2. Slot oder Mahlzeitentyp
3. Rezept oder freier Mahlzeiteneintrag
4. Portionszahl
5. spaeter optional verantwortliche Personen

Der Meal Plan ist die Quelle fuer strukturierte Essensplanung, nicht fuer die operative Einkaufsorganisation.

### 2. ShoppingRequirement

`ShoppingRequirement` ist die Quelle der Wahrheit fuer benoetigten Bedarf innerhalb eines Trips.

Ein Requirement repraesentiert:

1. einen benoetigten Artikel
2. eine benoetigte Menge in einer bestimmten Einheit
3. eine Herkunft
4. einen Synchronisierungszustand

Pflichtattribute:

1. `trip_id`
2. `food_item_id` optional, falls der Bedarf auf einem bekannten Standardartikel basiert
3. `name`
4. `quantity`
5. `unit`
6. `category`
7. `source_type`
8. `sync_status`
9. `notes` optional

Ergaenzende Herkunftsattribute:

1. `meal_plan_id` optional
2. `recipe_id` optional
3. `source_label` optional
4. `source_signature` optional
5. `last_synced_signature` optional
6. `synced_at` optional

Moegliche `source_type`-Werte:

1. `meal_plan`
2. `manual`
3. spaeter optional `template`
4. spaeter optional `carry_over`

Moegliche `sync_status`-Werte:

1. `manual`
2. `in_sync`
3. `outdated`
4. `manually_adjusted`
5. `detached`

Bedeutung:

1. `manual`
   - rein manuell erstellt, keine Meal-Plan-Bindung
2. `in_sync`
   - Requirement entspricht dem aktuellen Meal-Plan-Stand
3. `outdated`
   - Meal Plan oder Rezept hat sich seit der letzten Synchronisierung geaendert
4. `manually_adjusted`
   - der Bedarf stammt aus dem Meal Plan, wurde aber inhaltlich manuell veraendert
5. `detached`
   - der Bedarf stammt historisch aus dem Meal Plan, ist aber bewusst aus der Bindung geloest

### 3. ShoppingList

`ShoppingList` repraesentiert eine konkrete Einkaufsliste fuer einen bestimmten Einkaufszweck.

Beispiele:

1. `Aldi`
2. `Wochenmarkt`
3. `Getraenke`
4. `Ankunftsabend`

Pflichtattribute:

1. `trip_id`
2. `name`

Optionale Attribute:

1. `description`
2. `position`
3. `archived_at`

Bewusste Entscheidung:

1. Ein Trip kann mehrere Listen gleichzeitig haben.
2. Eine Liste ist keine Quelle der Wahrheit fuer den Bedarf.
3. Eine Liste ist eine operative Sammlung fuer einen Einkaufszweck.

### 4. ShoppingListAssignment

`ShoppingListAssignment` verbindet einen Bedarf mit einer konkreten Einkaufsliste.

Ein Requirement kann:

1. gar keiner Liste zugeordnet sein
2. genau einer Liste zugeordnet sein
3. auf mehrere Listen gesplittet sein

Pflichtattribute:

1. `shopping_requirement_id`
2. `shopping_list_id`
3. `planned_quantity`
4. `purchased_quantity`
5. `unit`

Optionale Attribute:

1. `position`
2. `notes`
3. `detached_from_requirement` optional fuer spaetere Feinsteuerung

Abgeleitete Werte:

1. `remaining_quantity = planned_quantity - purchased_quantity`
2. `purchase_status = open / partial / done`

Wichtige Regel:

1. Der Split passiert auf Assignment-Ebene.
2. Beispiel:
   - Requirement: `2 kg Tomaten`
   - Assignment 1: `1 kg Wochenmarkt`
   - Assignment 2: `1 kg Aldi`

### 5. ShoppingItemComment

Die Kommentarfunktion gehoert zur finalen Loesung und sollte nicht als Fremdkoerper spaeter drangehaengt werden.

Kommentar-Zielobjekt in der ersten finalen Version:

1. `ShoppingListAssignment`

Warum:

1. Kommentare sind meist kontextbezogen auf den realen Einkauf
2. Beispiel:
   - `Keine reifen im Edeka`
   - `Bitte kauf du die im Rewe`
3. Diese Kommunikation passt besser an die konkrete Listenposition als an den abstrakten Requirement-Bedarf

Pflichtattribute:

1. `shopping_list_assignment_id`
2. `user_id`
3. `body`

Optionale Attribute:

1. `resolved_at`
2. `edited_at`

### 6. ShoppingSyncRun

Fuer Nachvollziehbarkeit und Undo sollte die Synchronisierung als eigene Aktion modelliert werden.

`ShoppingSyncRun` repraesentiert einen expliziten Sync-Vorgang.

Pflichtattribute:

1. `trip_id`
2. `user_id`
3. `started_at`
4. `finished_at`
5. `undo_token`

Optionale Metadaten:

1. `change_summary`
2. `snapshot_payload`

Ziel:

1. Aenderungen eines Sync-Laufs dokumentieren
2. direktes `Undo` auf zuletzt ausgefuehrten Sync erlauben

### 7. FoodItem

`FoodItem` wird zur Standardartikel-Basis fuer Rezepte, Requirements und manuelle Shopping-Eintraege.

Pflichtattribute:

1. `name`
2. `default_category`
3. `default_unit`
4. `unit_type`

Optionale Attribute:

1. `aliases`
2. `search_tokens`
3. `preferred_store_category`
4. `notes`

Pragmatische Default-Regel:

1. Standard ist `kg` oder `l`
2. offensichtliche Stueckartikel nutzen `pieces`
3. spaetere Praezisierung ist erlaubt und erwartet

## Grenzen zwischen Planung und Einkauf

### Pflegeansicht

Die Pflegeansicht arbeitet auf Requirements.

Sie soll ermoeglichen:

1. Bedarfe aus Meals nachvollziehen
2. manuelle Bedarfe hinzufuegen
3. veraltete oder driftende Bedarfe erkennen
4. Bedarfe auf konkrete Listen verteilen
5. Splits pflegen
6. Synchronisierung explizit triggern

Wichtige Sichtbarkeit in dieser Ansicht:

1. Herkunft pro Requirement
2. Sync-Status
3. bereits zugewiesene Mengen
4. noch nicht zugewiesene Mengen

### Einkaufsansicht

Die Einkaufsansicht arbeitet auf Assignments.

Sie soll ermoeglichen:

1. Fokus auf eine konkrete Liste
2. schnelle mobile Bedienung
3. Teilkaeufe
4. Kommentare
5. Fortschritt pro Liste

Dort ist Aggregation gewuenscht, solange sie fachlich sicher bleibt.

## Synchronisierung

## Ausgangspunkt

Meal Plans und Rezepte aendern sich.
Shopping-Arbeit darf dabei nicht still ueberschrieben werden.

## Source Signature

Jedes meal-plan-basierte Requirement braucht eine berechenbare `source_signature`.

Sie sollte mindestens enthalten:

1. `meal_plan_id`
2. `recipe_id` oder freier Meal-Identifier
3. skalierten Zutatenstand
4. Portionszahl
5. relevante Einheiten

Ziel:

1. spaeter vergleichen zu koennen, ob der aktuelle Meal-Plan-Stand noch identisch ist

## Sync-Ablauf

Ein manueller Sync fuer einen Trip sollte so laufen:

1. aktuelle erwartete Requirements aus dem Meal Plan neu berechnen
2. mit bestehenden meal-plan-basierten Requirements abgleichen
3. Requirements als:
   - unveraendert
   - neu
   - entfernt
   - geaendert
   klassifizieren
4. existierende manuelle Requirements unberuehrt lassen
5. bei geaenderten Requirements nicht still Listenarbeit verlieren
6. `ShoppingSyncRun` mit diff-artigem Snapshot speichern
7. `Undo` fuer den letzten Sync anbieten

## Sync-Regeln fuer bestehende Requirements

### Fall A: unveraendert

1. `sync_status` bleibt `in_sync`
2. bestehende Assignments bleiben erhalten

### Fall B: Mengen- oder Inhaltsaenderung im Meal Plan

1. Requirement wird `outdated`
2. UI markiert den Drift
3. Nutzer kann explizit `Synchronize` ausfuehren

### Fall C: Synchronize wird bestaetigt

1. Requirement wird auf den aktuellen Meal-Plan-Stand aktualisiert
2. vorhandene Assignments bleiben nach Moeglichkeit erhalten
3. wenn Mengen nicht mehr passen, werden offene Deltas sichtbar
4. Sync-Aktion ist rueckgaengig

### Fall D: Requirement wurde manuell geaendert

1. `sync_status` wird `manually_adjusted`
2. spaetere Syncs duerfen nicht still darueberschreiben
3. UI soll eine bewusste Entscheidung anbieten:
   - beibehalten
   - mit Meal Plan abgleichen
   - bewusst loesen

## Undo

Ein `Undo` sollte sich auf den letzten `ShoppingSyncRun` beziehen.

Pragmatische erste Umsetzung:

1. nur letzter Sync-Run rueckgaengig
2. snapshot-basierte Ruecksetzung der betroffenen Requirements und Assignments
3. Undo-Zeitfenster sichtbar in der UI

## Einheiten und Aggregation

## Merge-Regeln

Nur sicher kompatible Einheiten werden automatisch zusammengefuehrt.

### Sicher kompatibel

1. `g` und `kg`
2. `ml` und `l`
3. `pieces`, `pcs`, `items`

### Nicht automatisch kompatibel

1. `5 grosse Tomaten` und `1 kg Tomaten`
2. `1 bundle Petersilie` und `30 g Petersilie`
3. `2 bottles Bier` und `1 crate Bier`

## Modellierung fuer unsichere Einheiten

Unsichere Einheiten bleiben getrennte Requirements oder getrennte aggregierte Zeilen.

Beispiel:

1. `Tomaten - 1 kg`
2. `Tomaten - 5 Stk (gross)`

Wenn beide spaeter im UI eng gruppiert dargestellt werden, ist das rein visuelle Gruppierung, keine rechnerische Fusion.

## Kategorien

Sowohl Requirements als auch Assignments sollen Kategorien tragen koennen.

Grund:

1. Einkaufsansichten profitieren von Kategorie-Sections
2. Default-Kategorien kommen aus `FoodItem`
3. manuelle Uebersteuerung bleibt erlaubt

## Wiederverwendung zwischen Trips

Die finale Loesung sollte Wiederverwendung explizit mitdenken.

Technisch naheliegende spaetere Erweiterung:

1. `TripTemplate`
2. `TemplateMealPlan`
3. `TemplateShoppingRequirement`
4. `TemplateShoppingList`

Wichtig:

1. Wiederverwendung ist keine Kopie der historischen Live-Daten ohne Struktur.
2. Es braucht wiederverwendbare Vorlagen.
3. Lessons Learned sollen spaeter in diese Vorlagen einfliessen koennen.

## Lessons Learned

Der Trip soll nach Abschluss Erfahrungswissen speichern koennen.

Sinnvolle spaetere Einheit:

1. `TripLesson`

Moegliche Attribute:

1. `trip_id`
2. `body`
3. `category`
4. `attachment`
5. `related_food_item_id` optional
6. `related_template_id` optional

Beispiele:

1. `Zu viel Kaese gekauft`
2. `Zu wenig Tomaten fuer 8 Personen`
3. `Markt war montags geschlossen`

## Empfohlene Implementierungsphasen

### Phase 1 - neues Kernmodell

Ziel:

1. `ShoppingRequirement`
2. `ShoppingList`
3. `ShoppingListAssignment`
4. `ShoppingSyncRun`
5. `FoodItem`-Defaults vorbereiten

Bewusste Entscheidung:

1. bestehende `ShoppingItem`-Logik nicht weiter ausbauen
2. lieber neues Modell sauber daneben oder als Ersatz aufbauen

### Phase 2 - Service Layer

Zielservices:

1. `Shopping::RequirementBuilder`
2. `Shopping::RequirementSynchronizer`
3. `Shopping::AssignmentSplitter`
4. `Shopping::AssignmentAggregator`
5. `Shopping::UndoSync`

### Phase 3 - Pflegeansicht

Ziel:

1. Requirement-zentrierte Planungsseite
2. Herkunft und Sync-Status sichtbar
3. Split auf mehrere Listen moeglich
4. manuelle Bedarfe moeglich

### Phase 4 - Einkaufsansicht

Ziel:

1. eine konkrete Liste mobil benutzbar machen
2. Teilkaeufe
3. Fortschritt
4. Kategorien
5. schnelle Interaktion

### Phase 5 - Kommentare

Ziel:

1. Kommentare auf `ShoppingListAssignment`
2. leichte Abstimmung waehrend des Einkaufens

### Phase 6 - Wiederverwendung und Lessons Learned

Ziel:

1. wiederverwendbare Vorlagen
2. strukturierte Rueckschau nach Trips
3. spaeter Verknuepfung mit Planung und Shopping

## Offene Detailfragen fuer spaetere Ausarbeitung

Diese Punkte blockieren das Zielmodell nicht, muessen aber spaeter konkretisiert werden:

1. wie fein `who cooks` und Verantwortlichkeiten im ersten finalen Meal-Plan-Schnitt abgebildet werden --> default leer, auswählen von gästen möglich
2. welche Store-Metadaten eine Liste ausser Name und Beschreibung braucht --> keine
3. wie strukturiert `TripLesson` am Anfang sein soll --> unstrukturiert ist ok. Bild upload gewünscht
