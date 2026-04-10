# Shopping Workflow Concept

Stand: 2026-04-10

## Zweck

Dieses Dokument praezisiert das fachliche Zielbild fuer `Meal Planning` und `Shopping` auf Workflow-Ebene.
Der Fokus liegt auf:

1. mehreren Einkaufslisten pro Trip
2. Trennung zwischen Pflegeansicht und Einkaufsansicht
3. manueller Synchronisierung vom Meal Plan in die Einkaufslogik
4. sicheren Regeln fuer Aggregation und Einheiten

Es ist bewusst ein Fach- und Produktdokument, kein UI-Pixel-Spec und kein sofortiger Datenmigrationsplan.

Wichtig:

1. Es geht nicht um eine halbe Zwischenloesung.
2. Der bestehende Shopping-/Meal-Planning-Code ist nicht schutzwuerdig.
3. Das Ziel ist eine endgueltige, UX-getriebene Loesung, die real im Alltag benutzt werden kann.

## Leitidee

`Meal Planning` und `Shopping` bleiben getrennte, aber verbundene Ebenen:

1. `Meal Planning` ist die Planungs- und Strukturansicht.
2. `Shopping` ist die operative Beschaffungsansicht.
3. Die Verbindung zwischen beiden ist synchronisierbar, aber nicht vollautomatisch versteckt.

## Kernentscheidung

Ein Trip kann mehrere Einkaufslisten haben.

Beispiele:

1. `Aldi`
2. `Wochenmarkt`
3. `Getraenke`
4. `Baeckerei`

Das ist kein Randfall, sondern ein realistischer Anwendungsfall fuer echte Trips.

## Ziel-Workflow

### 1. Planungsansicht

Die Planungsansicht organisiert:

1. Tage
2. Mahlzeiten
3. Rezepte
4. Personenanzahl
5. optional spaeter Verantwortlichkeiten

Wichtig:

1. Jede Mahlzeit bleibt dort separat sichtbar.
2. Ihre benoetigten Zutaten koennen dort nachvollziehbar angezeigt werden.
3. Nutzer muessen verstehen koennen, welche Einkaeufe aus welcher Mahlzeit kommen.

### 2. Pflegeansicht fuer Einkaufsbedarf

Zwischen Meal Plan und eigentlichem Einkaufen braucht es eine dedizierte Pflegeansicht.

Diese Ansicht dient dazu:

1. aus Meals erzeugte Bedarfe zu sehen
2. manuelle Bedarfe hinzuzufuegen
3. Bedarfe zu aggregieren
4. Bedarfe auf konkrete Einkaufslisten zu verteilen
5. Aenderungen aus dem Meal Plan bewusst zu synchronisieren

Diese Ansicht ist die Arbeitsansicht fuer:

1. Planen
2. Sortieren
3. Verteilen
4. Aufraeumen

Nicht die eigentliche In-Store-Einkaufsansicht.

### 3. Einkaufsansicht

Die Einkaufsansicht ist die operative Ansicht fuer das echte Einkaufen.

Dort sollen Nutzer:

1. eine konkrete Liste wie `Aldi` oder `Wochenmarkt` oeffnen
2. aggregierte Positionen sehen
3. Teilmengen kaufen
4. Fortschritt sehen
5. schnell und mit wenig Reibung abhaken oder fortschreiben

Diese Ansicht ist nicht fuer komplexe Planung gedacht, sondern fuer:

1. Fokus
2. Geschwindigkeit
3. Mobilitaet
4. mehrere Personen gleichzeitig

## Unabhaengige manuelle Eintraege bleiben Pflicht

Shopping darf nie auf Meal Plans beschraenkt sein.

Nutzer muessen weiterhin:

1. komplett manuelle Bedarfe anlegen koennen
2. spontane Bedarfe ausserhalb von Meals erfassen koennen
3. reine Einkaufslisten ohne Meal-Plan-Bezug fuehren koennen

Das gilt besonders fuer:

1. Getraenke
2. Snacks
3. Huettenbedarf
4. Haushaltsbedarf
5. alles, was nicht sinnvoll einer Mahlzeit zugeordnet werden kann

## Mehrere Einkaufslisten pro Trip

### Entscheidung

Ein Trip hat nicht nur eine aktive Liste, sondern:

1. einen gemeinsamen Bedarfspool
2. daraus abgeleitete oder manuell gepflegte konkrete Einkaufslisten

### Fachliche Bedeutung

Die eigentliche Quelle der Wahrheit ist nicht die einzelne Liste, sondern der benoetigte Bedarf.

Eine konkrete Liste ist eher:

1. ein Einkaufsziel
2. eine Einkaufsroute
3. ein Store-/Zweck-spezifischer Ausschnitt

### Konsequenz

Meal-Plan-Bedarfe duerfen nicht direkt nur in eine einzige fixe Liste geschrieben werden, wenn wir es richtig bauen wollen.

Stattdessen brauchen wir fachlich mindestens diese Ebenen:

1. `ShoppingRequirement`
   - der benoetigte Bedarf
2. `ShoppingList`
   - eine konkrete Einkaufsliste wie `Aldi`
3. `ShoppingListItem`
   - die Zuordnung eines Bedarfs zu einer Liste

Wichtig:

1. Ein Requirement darf auf mehrere Listen aufteilbar sein.
2. Beispiel:
   - `2 kg Tomaten`
   - `1 kg Wochenmarkt`
   - `1 kg Aldi`

## Warum das noetig ist

Beispiel:

1. `Gemueselasagne` braucht
   - Tomaten
   - Zucchini
   - Lasagneblaetter
   - Kaese
2. Tomaten und Zucchini sollen auf den `Wochenmarkt`
3. Lasagneblaetter und Kaese zu `Aldi`

Wenn der Meal Plan direkt nur fertige Listenitems erzeugt, verliert man diese Flexibilitaet oder muss spaeter sehr unsauber umbauen.

## Synchronisierung statt versteckter Automatik

Wenn ein Rezept oder Meal spaeter geaendert wird, soll die Einkaufslogik nicht still und unsichtbar Dinge ueberschreiben.

Stattdessen:

1. es gibt eine manuell ausloesbare Synchronisierung
2. das System erkennt, ob ein Einkaufsbedarf noch dem aktuellen Meal-Plan-Stand entspricht
3. veraltete oder driftende Eintraege werden sichtbar markiert

## Vorgeschlagenes Synchronisierungsmodell

### Meal Plan erzeugt Requirements

Jede geplante Mahlzeit erzeugt oder aktualisiert Requirements:

1. pro Zutat
2. mit Bezug auf:
   - `meal_plan`
   - `recipe`
   - Mengenstand
   - Portionszahl

### Requirement kennt Sync-Status

Ein Requirement sollte mittelfristig z. B. kennen:

1. `source_signature`
2. `synced_at`
3. `sync_status`

Moegliche Stati:

1. `in_sync`
2. `outdated`
3. `manually_adjusted`
4. `detached`

### Bedeutung

1. `in_sync`
   - Requirement entspricht dem Meal-Plan-Stand
2. `outdated`
   - Meal oder Rezept wurde geaendert, Requirement ist veraltet
3. `manually_adjusted`
   - Nutzer hat Requirement oder Zuordnung bewusst veraendert
4. `detached`
   - Item lebt absichtlich weiter unabhaengig vom Meal Plan

### Sync-Verhalten

Die Synchronisierung soll:

1. manuell triggerbar sein
2. veraltete oder driftende Eintraege markieren
3. eine Synchronisierung mit einem Klick erlauben
4. direkt danach eine `Undo`-Moeglichkeit anbieten

Das Ziel ist:

1. bewusste Kontrolle statt stiller Ueberschreibung
2. trotzdem moeglichst wenig Reibung im Alltag

## Aggregation

### In der Planungs-/Pflegeansicht

Dort sollen Mahlzeiten eher separat oder halb-separat nachvollziehbar bleiben.

Ziel:

1. Verstehen, woher der Bedarf kommt
2. sinnvoll auf Einkaufslisten verteilen
3. Konflikte oder Aenderungen erkennen

Zusatz:

1. Die Pflegeansicht darf Requirements pro Mahlzeit sichtbar machen.
2. Nutzer sollen also verstehen koennen:
   - diese Zutat kommt aus genau dieser Mahlzeit
   - diese Position wurde bereits einer oder mehreren Einkaufslisten zugeordnet
   - diese Position ist veraltet oder geaendert

### In der Einkaufsansicht

Dort darf und soll aggregiert werden:

1. gleiche Artikel zusammenlegen
2. Fortschritt pro Einkaufsliste sichtbar machen
3. offene und erledigte Mengen kompakt anzeigen

## Einheiten und Zusammenfuehrung

### Sichere Zusammenfuehrung

Automatisch zusammenfuehren nur bei verlässlich kompatiblen Einheiten:

1. `g` und `kg`
2. `ml` und `l`
3. `pieces`, `pcs`, `items`

### Unsichere Zusammenfuehrung

Nicht automatisch zusammenfuehren:

1. `5 grosse Tomaten` und `1 kg Tomaten`
2. `1 Bund Petersilie` und `30 g Petersilie`
3. `2 Flaschen Bier` und `1 Kiste Bier`

### Regel

Unsichere Kombinationen bleiben getrennt.

Sie duerfen in der Einkaufsansicht:

1. optisch gruppiert
2. unter demselben Produktnamen zusammen angezeigt

werden, aber nicht rechnerisch verschmolzen.

## Seed-Daten fuer Standardartikel

Um Klicks zu sparen, wird `FoodItem` als Vorschlags- und Standardbasis ausgebaut.

### Ziel

Bei Zutaten und manuellen Shopping-Items sollen Name, Kategorie und Einheit moeglichst vorbefuellt werden.

### Erste pragmatische Default-Regel

Vorlaeufig:

1. `kg` fuer viele Lebensmittel mit Gewichtslogik
2. `l` fuer viele Fluessigkeiten
3. `pieces` fuer offensichtliche Ausnahmen

Typische offensichtliche Ausnahmen:

1. Salatkopf
2. Gurke
3. Avocado
4. Zwiebel
5. Zitrone
6. Mozzarella

Diese Regel ist bewusst pragmatisch und spaeter verfeinerbar.

## Wiederverwendung zwischen Trips

Shopping und Meal Planning sollen wiederverwendbar werden.

Das ist kein Nice-to-have, sondern ein realistischer Kernfall.

Beispiele:

1. jaehrliches Huettenwochenende mit denselben Freunden
2. wiederkehrender Sommertrip
3. Familienwochenende mit aehnlicher Einkaufsbasis

### Konsequenz

Es sollte spaeter moeglich sein:

1. Meal-Plan-Strukturen wiederzuverwenden
2. Einkaufsbedarfe oder Einkaufslisten wiederzuverwenden
3. daraus einen neuen Trip-Stand zu erzeugen

Das spricht fuer eine Template- oder Blueprint-Ebene.

## Lessons Learned

Am Ende eines Trips soll festgehalten werden koennen:

1. was gefehlt hat
2. was zu viel war
3. was naechstes Mal anders geplant werden sollte
4. optionale Fotos oder andere Artefakte

Beispiele:

1. `zu viel Kaese gekauft`
2. `zu wenig Tomaten`
3. `Biermenge war passend`

### Bedeutung

Diese Informationen sollen spaeter in Wiederverwendung und Planung einfliessen koennen.

Das spricht dafuer, dass `Lessons Learned` nicht nur Freitext im Nirgendwo sind, sondern einem Trip oder spaeter einem wiederverwendbaren Blueprint zugeordnet werden.

## Data Model Direction

### Zielmodell

Der aktuelle Code darf vollstaendig ersetzt oder neu geschnitten werden.

Fachlich ist das Ziel:

1. `MealPlan`
2. `ShoppingRequirement`
3. `ShoppingList`
4. `ShoppingListAssignment` oder `ShoppingListItem`
5. spaeter `ShoppingItemComment`
6. spaeter `TripTemplate` oder `PlanningBlueprint`
7. spaeter `TripLesson`

### Bedeutungen

`ShoppingRequirement`

1. benoetigter Bedarf
2. kann aus Meal Plan oder manuell entstehen
3. kennt Quelle und Sync-Zustand
4. kann unverteilt sein oder auf mehrere Listen verteilt werden

`ShoppingList`

1. konkrete Einkaufsliste
2. z. B. `Aldi`, `Wochenmarkt`, `Getraenke`
3. darf optionale Metadaten wie Name und Beschreibung tragen

`ShoppingListItem` / `Assignment`

1. verweist auf Requirement
2. liegt in genau einer Liste
3. bildet eine Teilmenge eines Requirements ab
4. hat den Einkaufsfortschritt fuer diese Liste

`ShoppingItemComment`

1. Kommentar an einem konkreten Einkaufslisten-Eintrag
2. fuer Abstimmung waehrend Planung oder Einkauf
3. nicht erste Ausbaustufe, aber Teil der finalen Zielrichtung

`TripTemplate` / `PlanningBlueprint`

1. wiederverwendbarer Satz aus Meals, Einkaufsbedarfen oder beidem
2. als Ausgangspunkt fuer spaetere Trips

`TripLesson`

1. retrospektive Erkenntnis aus einem abgeschlossenen Trip
2. optional mit Bild oder Attachment
3. dient der Verbesserung kuenftiger Wiederverwendung

## Fortschritt und Teil-Einkauf

Teil-Einkaeufe bleiben fachlich gewuenscht.

Das bedeutet:

1. benoetigte Menge
2. gekaufte Menge
3. offene Menge

Das gilt in der Einkaufsansicht pro Listen-Eintrag.

## Manuelle Items

Manuelle Items bleiben gleichwertig.

Sie koennen:

1. direkt in der Pflegeansicht entstehen
2. sofort einer Liste zugeordnet werden
3. spaeter optional ohne Meal-Plan-Bezug bestehen

Beispiele:

1. Bier
2. Wasser
3. Kohle
4. Spuelmittel
5. Fruehstuecks-Basics

## Vorlaeufige Entscheidungen

Ab jetzt gelten fuer die weitere Arbeit:

1. Ein Trip kann mehrere Einkaufslisten haben.
2. Es braucht eine Pflegeansicht und eine getrennte Einkaufsansicht.
3. Meal-Plan-Bedarfe werden nicht still automatisch in Einkaufslisten festgeschrieben.
4. Synchronisierung vom Meal Plan ist manuell triggerbar.
5. Das System soll Drift zwischen Meal Plan und Einkaufsstand sichtbar machen.
6. Eine Synchronisierung soll per Klick moeglich sein und direkt `Undo` erlauben.
7. Requirements duerfen auf mehrere Einkaufslisten aufgeteilt werden.
8. Sichere Einheiten duerfen aggregiert werden.
9. Unsichere Einheiten bleiben getrennt.
10. `FoodItem` wird als Seed- und Vorschlagsbasis ausgebaut.
11. Shopping und Meal Plans sollen spaeter zwischen Trips wiederverwendbar werden.
12. `Lessons Learned` sollen als eigener Bestandteil mitgedacht werden.
13. Kommentare an Items gehoeren zur finalen Zielrichtung, auch wenn sie nicht zuerst gebaut werden.

## Noch offene Detailfragen

Diese Punkte koennen spaeter entschieden werden, blockieren das Grundmodell aber nicht:

1. wie stark `who cooks` schon in der ersten Meal-Plan-Ausbaustufe beruecksichtigt wird
2. welche Store-Metadaten ueber Name und optionale Beschreibung hinaus sinnvoll sind
3. wie fein `Lessons Learned` spaeter strukturiert werden sollen
