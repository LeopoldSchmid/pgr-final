# Meal Plan Finalization Spec (UX + Funktion)

Stand: 2026-04-17

## Implementierungsstatus

Stand 2026-04-17 (Code + Tests):

1. Block A abgeschlossen.
2. Block B abgeschlossen.
3. Block C abgeschlossen.
4. Block D abgeschlossen.
5. Block E abgeschlossen.
6. Block F abgeschlossen.
7. Block G abgeschlossen.

Validiert mit:

1. Model/Service/Controller-Tests fuer Meal/Shopping-Finalisierung.
2. Rails Systemtest `test/system/meal_planning_test.rb` (Playwright-basiert).

## Zweck

Dieses Dokument ist die verbindliche Spezifikation fuer die Finalisierung von:

1. `Meal Plan`
2. `Shopping Plan`
3. `Shopping List`

Fokus ist ein runder, alltagstauglicher End-to-End-Flow mit geringer Reibung auf Mobile.

## Verbindliche Produktentscheidungen

1. Header und obere App-Navigation bleiben unveraendert.
2. Der Flow bleibt strikt: `Meal Plan -> Shopping Plan -> Shopping List`.
3. `Zur Einkaufsliste` in Meal Plan navigiert nicht weg, sondern aktualisiert nur den `Shopping Plan`.
4. Meal-basierte Positionen sind standardmaessig shopping-relevant.
5. Im Shopping Plan kann pro Mahlzeit markiert werden: `Diese Mahlzeit bringe ich mit` als transparente Erledigungsaktion.
6. Meal-Typen sind fix und in dieser Reihenfolge:
   - `Fruehstueck`
   - `Mittag`
   - `Abend`
   - `Snack`
   - `Sonstiges`
   - `Getraenke`
7. Avatare/Zustaendigkeiten in Meal Plan sind funktional, nicht nur dekorativ.
8. Rezept-Drift wird angezeigt; Merge erfolgt nur als Ganzes (kein Zeilen-Merge).
9. UX soll kompakt sein, ohne redundante Erklaertexte, ohne tote Flaechen.
10. `Back to Shopping Plan` und `Trip Shopping List` werden nicht wieder eingefuehrt.

## Zielbild Meal Plan

## Layout und Navigation

1. Oben: bestehender Header + bestehende Bereichsnavigation (unveraendert).
2. Mobile zeigt zunaechst genau einen Tag gleichzeitig.
3. Datumsauswahl als horizontale Chips.
4. Innerhalb eines Tages: vertikale Meal-Type-Chips als schnelle Sprungleiste.
5. Vertikale Chips zeigen:
   - Label
   - Anzahl geplanter Meals
   - aktiven Zustand (Scrollspy)
6. Long-Press auf Meal-Type-Chip oeffnet direkt `+ Mahlzeit` fuer diesen Typ.
7. Spaeterer Ausbau ist moeglich:
   - Tageswechsel als Carousel
   - partielle Ueberlappung des naechsten/vorherigen Tages

## Tages- und Sektionsstruktur

1. Pro Tag Sektionen fuer alle sechs Meal-Typen.
2. Jede Sektion hat `+ Mahlzeit` als direkten Einstieg.
3. Sektionen sind standardmaessig offen; kein staendiges Ein/Ausklappen als Primaerinteraktion.

## Meal Card

1. Kopfzeile:
   - Meal-Name oder Rezeptname
   - kleine Avatare der zugewiesenen Personen
   - kompakte Actions (edit/delete/duplicate)
2. Portionssteuerung direkt in der Karte (`-` / aktueller Wert / `+`).
3. Zutatenliste ist standardmaessig eingeklappt und pro Meal ausklappbar.
4. Im ausgeklappten Zustand: Menge+Einheit rechtsbuendig.
5. Wenn ein Meal ohne Zutatenbasis geplant ist, wird ein klarer Hinweis angezeigt (`Ingredients fehlen`), ohne das Meal zu blockieren.
6. CTA `Zur Einkaufsliste` als schnelle Action in der Karte.
7. Status-Badges moeglich:
   - `In Shopping Plan`
   - `Drift`
   - `Ingredients fehlen`

## Wiederverwendung: Einmal planen, mehrfach nutzen

Feature `Duplizieren auf...` in jeder Meal Card:

1. `morgen`
2. `alle restlichen Tage`
3. `bestimmte Tage`

Regel:

1. Standard ist Kopie als eigene Instanzen pro Tag.
2. Optional kann eine Serie verknuepft werden.
3. Bei Serie-Edit:
   - `nur diesen Tag`
   - `alle in Serie`

## Funktionale Regeln

## Erledigungslogik pro Meal-Quelle

Es gibt keinen separaten Einkaufsmodus auf Meal-Ebene.

Stattdessen:

1. Meal-basierte Requirements werden normal erzeugt.
2. In `Shopping Plan` kann pro Meal-Quelle die Aktion `Diese Mahlzeit bringe ich mit` ausgefuehrt werden.
3. Die Aktion markiert die zugehoerigen Positionen transparent als erledigt (nicht entfernt), sodass der Verlauf sichtbar bleibt.

## `Zur Einkaufsliste` (Meal Plan Action)

1. Aktion navigiert nicht weg.
2. Aktion markiert Meal fuer `Shopping Plan` Sync-Kontext.
3. Wenn Requirement-Sync noetig ist, wird `outdated` gesetzt und im Shopping Plan sichtbar.

## Drift gegen Rezept

Ziel: klare, robuste Aktualisierung ohne Mikrokonflikte.

Mechanik:

1. Beim Planen wird pro Meal eine Rezept-Signatur gespeichert.
2. Aendert sich Rezept/Ingredient-Basis, bekommt Meal Status `drift`.
3. UI zeigt `Drift`-Hinweis in Meal Card.
4. Action `Aenderungen pruefen` zeigt Diff-Preview (read-only):
   - hinzugefuegt
   - entfernt
   - geaendert
5. Merge-Optionen:
   - `Neue Rezeptversion komplett uebernehmen`
   - `Aktuellen Stand behalten`
6. Nach Gesamt-Uebernahme werden zugehoerige Shopping-Requirements als `outdated` markiert.

## Assignee-Logik (Avatare)

1. Meal kann 0..n verantwortliche Personen haben.
2. Auswahl nur aus Trip-Teilnehmern.
3. Assignee ist organisatorisch, nicht exklusiv fuer Schreibrechte.
4. Anzeige in Card als kompakte Avatar-Reihe.

## Zielbild Shopping Plan (Ergaenzung)

1. Grouping `By category` und `By source` bleibt.
2. In `By source` muss klar pro Meal erkennbar sein:
   - ob Positionen noch offen oder bereits erledigt sind
   - Drift-Status
3. Neue schnelle Massenaktion fuer Meal-Quelle:
   - `Diese Mahlzeit bringe ich mit`
4. Sync bleibt manuell triggerbar mit Undo.
5. Merge bei Drift bleibt ganzheitlich pro Meal (kein Ingredient-Level Accept/Reject).

## Datenmodell-Target (konkret)

## MealPlan

Erweiterungen:

1. `meal_type` um `miscellaneous`, `drinks` erweitern.
2. `servings` (decimal) fuer meal-spezifische Portionsmenge.
3. `recipe_snapshot_signature` (string)
4. `drift_status` (enum/string):
   - `in_sync`
   - `drifted`
   - `resolved`
5. optional `series_token` (string) fuer verknuepfte Serienkopien.

## MealPlanAssignee (neu)

1. `meal_plan_id`
2. `user_id`
3. unique index auf (`meal_plan_id`, `user_id`)

## Shopping Requirement Builder

1. Muss `MealPlan.servings` gegen `Recipe.servings` skalieren.
2. `source_label` bleibt meal-basiert (`date | meal_type | recipe`).

## ShoppingListAssignment (Ergaenzung)

1. `Diese Mahlzeit bringe ich mit` soll ueber vorhandene Mengenlogik als Erledigung abgebildet werden.
2. Optionales Audit-Feld fuer Herkunft der Erledigung:
   - `completion_source` (`purchase`, `brought_by_meal_source`)

## API/Controller-Aenderungen

## MealPlansController

Neue/erweiterte Actions:

1. `create/update/destroy` fuer neue Meal-Typen und `servings`.
2. `duplicate` mit Zielmodus (`next_day`, `rest_of_trip`, `selected_days`).
3. `set_assignees`.
4. `drift_preview`.
5. `resolve_drift` (`accept_new_recipe` oder `keep_current`).

## ShoppingPlansController

1. Source-Ansicht zeigt offen/erledigt klar pro Meal-Quelle.
2. Meal-spezifische Aktion `Diese Mahlzeit bringe ich mit`.
3. Sync/Undo unveraendert, aber Drift sichtbar priorisiert.

## UX-Details fuer mobile Geschwindigkeit

1. Interaktionen bevorzugt inline statt Modalketten.
2. Primaraktionen im Daumenbereich.
3. Keine langen Formtexte.
4. Keine doppelten Seitentitel unter aktiver Tab-Navigation.
5. Schnelles Erstellen einer Mahlzeit in maximal 3 Schritten:
   - Tag/Sektion
   - Rezept oder freier Name
   - Portionswert (default vorausgefuellt)

## Teststrategie (verbindlich)

## Controller/Model

1. Meal-Typen inkl. `miscellaneous` und `drinks`.
2. Portionierungsskalierung auf Requirements.
3. Erledigungsaktion `Diese Mahlzeit bringe ich mit` markiert source-bezogene Positionen korrekt.
4. Assignee CRUD und Zugriffsgrenzen.
5. Drift-Erkennung + Gesamtmerge.
6. Duplizieren auf mehrere Tage inkl. Serie-Option.

## System/Playwright

Mindestens diese Flows:

1. Meal erstellen -> `Zur Einkaufsliste` -> Requirement im Shopping Plan sichtbar.
2. `Diese Mahlzeit bringe ich mit` markiert die zugehoerigen Positionen als erledigt.
3. Recipe aendern -> Drift sichtbar -> Gesamtuebernahme -> Sync aktualisiert Requirements.
4. Meal duplizieren auf mehrere Tage.
5. Assignees setzen und in Card sichtbar.

## Abnahmekriterien

Die Finalisierung gilt erst als abgeschlossen, wenn alle Punkte erfuellt sind:

1. Neues Meal-Plan-UI entspricht der spezifizierten Interaktionsstruktur.
2. Alle sechs Meal-Typen funktionieren durchgaengig.
3. `Zur Einkaufsliste` arbeitet ohne Seitenwechsel und ohne Inkonsistenz.
4. `Diese Mahlzeit bringe ich mit` funktioniert pro Meal-Quelle und markiert Positionen transparent als erledigt.
5. Drift wird erfasst, angezeigt und nur als Ganzes aufloesbar.
6. Ingredients sind standardmaessig eingeklappt und ausklappbar.
7. Meal ohne Ingredients ist fuer initiale Planung moeglich, aber klar gekennzeichnet.
8. Duplizieren auf mehrere Tage funktioniert robust.
9. Avatare/Assignees sind funktional.
10. Controller- und E2E-Tests sind gruen.
11. Keine Rueckkehr zu redundanten Controls (`Back to Shopping Plan`, `Trip Shopping List`).

## Implementierungsreihenfolge (kleinteilige Bloecke)

1. Block A: Datenmodell + Validation + Migrationen + Unit-Tests.
2. Block B: MealPlansController-Endpunkte + Controller-Tests.
3. Block C: Meal-Plan-UI-Struktur (Chips, Sektionen, Cards) ohne Drift.
4. Block D: Assignees + Duplizieren auf Tage/Serie.
5. Block E: Shopping-Integration (`Zur Einkaufsliste`, `Diese Mahlzeit bringe ich mit` als Erledigungsaktion).
6. Block F: Drift-Preview und Gesamtmerge.
7. Block G: Playwright-End-to-End + Bugfix-Runde + Doku-Update.

Dieses Dokument ist die Arbeitsgrundlage fuer die Umsetzung.
