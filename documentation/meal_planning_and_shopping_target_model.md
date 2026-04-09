# Meal Planning And Shopping Target Model

Stand: 2026-04-09

## Zweck

Dieses Dokument definiert das fachliche Zielmodell fuer `Meal Planning` und `Shopping`.
Es ist kein UI-Konzept und kein sofortiger Implementierungsplan, sondern die inhaltliche Referenz dafuer, wie diese beiden Bereiche kuenftig zusammenspielen sollen.

## Kernidee

`Meal Planning` und `Shopping` sind eng verbunden, aber nicht dasselbe.

1. `Meal Planning` dient der kooperativen Essens- und Kochplanung.
2. `Shopping` dient der realen Beschaffung fuer den Trip.
3. Shopping kann aus Meals abgeleitet werden, muss aber auch unabhaengig und gemischt funktionieren.

## Produktziele

### 1. Kooperative Mahlzeitenplanung

Die App soll helfen zu planen:

1. was gekocht oder gegessen wird
2. wann es stattfindet
3. fuer wie viele Personen geplant wird
4. optional wer kocht oder verantwortet

### 2. Zusammengefuehrte Einkaufslogik

Die App soll daraus einen real nutzbaren Einkaufsbedarf machen:

1. aggregierte Zutaten aus geplanten Rezepten
2. zusaetzliche manuelle Positionen
3. sinnvolle Gruppierung und Verdichtung
4. keine kuenstliche Bindung aller Positionen an einzelne Meals

### 3. Kooperatives Einkaufen

Die App soll Einkaufen nicht nur als `offen / erledigt` behandeln.

Beispiel:

1. benoetigt: `2 kg Tomaten`
2. Person A kauft: `1 kg`
3. offen bleiben: `1 kg`

Das ist naeher an echten Trip-Szenarien als ein reiner Checkbox-Status.

## Fachliche Abgrenzung

### Meal Planning

Meal Planning beantwortet:

1. Welche Mahlzeiten sind geplant?
2. Welche Rezepte gehoeren dazu?
3. Fuer wie viele Personen wird geplant?
4. Wer kocht oder uebernimmt die Mahlzeit?

Meal Planning ist damit primär:

1. Koordination
2. Struktur
3. gemeinsame Planung

### Shopping

Shopping beantwortet:

1. Was muss insgesamt besorgt werden?
2. Was ist schon teilweise oder vollstaendig gekauft?
3. Was stammt aus Meal Plans?
4. Was wurde manuell ergaenzt?

Shopping ist damit primär:

1. Beschaffung
2. operative Realitaet
3. kooperative Erledigung

## Warum Shopping nicht nur aus Meals abgeleitet werden darf

Nicht jeder reale Bedarf passt auf einzelne Mahlzeiten.

Typische Gegenbeispiele:

1. Bier fuer ein Huettenwochenende
2. Wasser, Kaffee, Tee
3. Snacks
4. Oel, Salz, Gewuerze als Grundbedarf
5. Fruehstuecksgrundlagen fuer mehrere Tage
6. Haushaltssachen wie Spuelmittel oder Klopapier

Folgerung:

1. Shopping List muss eigenstaendig nutzbar sein
2. Meal Plans sind eine Quelle fuer Bedarf, aber nicht die einzige

## Zielmodell

### 1. Shopping List bleibt das zentrale Arbeitsobjekt

Eine `ShoppingList` ist die konkrete Liste, mit der Nutzer arbeiten.

Sie kann entstehen:

1. komplett manuell
2. komplett aus Meal Plans abgeleitet
3. als Mischform aus beidem

### 2. Meal Plans erzeugen Vorschlaege oder Bedarfe

Meal Plans liefern Input fuer Shopping, aber nicht die einzige Wahrheit.

Das bedeutet:

1. Rezepte und geplante Meals koennen Zutaten in die Shopping List ueberfuehren
2. danach darf die Shopping List frei weiterbearbeitet werden
3. manuelle Items sind gleichwertig, nicht nur ein Notbehelf

### 3. Shopping Items brauchen Teil-Erfuellung

Ein Shopping Item sollte fachlich mindestens kennen:

1. benoetigte Menge
2. bereits gekaufte Menge
3. verbleibende Menge

Ein reines Boolean `purchased` ist dafuer zu grob.

Sinnvolle Statusableitung:

1. `open`
2. `partial`
3. `done`

### 4. Herkunft eines Shopping Items bleibt sichtbar

Mindestens zwei Quellen sind relevant:

1. `meal_plan`
2. `manual`

Spaeter moeglich:

1. `template`
2. `carry_over`
3. `trip_supply`

## Empfohlenes Datenmodell

### Erste sinnvolle Ausbaustufe

`ShoppingItem` sollte mittelfristig eher diese Semantik tragen:

1. `required_quantity`
2. `purchased_quantity`
3. `unit`
4. `category`
5. `source_type`

Abgeleitet:

1. `remaining_quantity`
2. `status`

Das ist die pragmatische erste Stufe ohne zu viel Komplexitaet.

### Zweite sinnvolle Ausbaustufe

Falls kooperatives Einkaufen aktiv genutzt wird, ist ein eigenes Modell fuer Kaufbeitraege sinnvoll:

`ShoppingItemPurchase`

1. `shopping_item_id`
2. `user_id`
3. `quantity`
4. optional `note`

Nutzen:

1. mehrere Personen koennen parallel kaufen
2. Teilkaeufe bleiben nachvollziehbar
3. spaetere Historie und Konfliktaufloesung werden einfacher

## Was das fuer die aktuelle App bedeutet

### Beibehalten

1. Meal Plans als Quelle fuer planbare Mahlzeiten
2. Shopping List als eigenes Objekt
3. manuelle Shopping Items

### Nicht weiter verstaerken

1. Shopping nur als direkte Meal-Ableitung
2. Shopping nur mit `purchased true/false`
3. die Annahme, dass jedes Einkaufsitem genau einer Mahlzeit zugeordnet sein muss

### Mittelfristige Richtung

1. Shopping List als gemischte Arbeitsliste aus generierten und manuellen Positionen
2. bessere Aggregation ueber mehrere Meals
3. Teil-Erfuellung statt nur Checkbox-Status
4. optionale Verantwortlichkeiten bei Meals und spaeter ggf. auch beim Einkauf

## Nicht-Ziele dieses Dokuments

1. keine Festlegung auf konkretes UI
2. keine sofortige Datenmigration
3. kein direkter Umbau aller bestehenden Modelle in einem Schritt

## Konsequenz fuer die weitere Arbeit

Die naechsten Implementierungen in `Meal Planning` und `Shopping` sollten gegen diese Regeln geprueft werden:

1. Hilft es kooperativer Planung?
2. Hilft es realer Einkaufsorganisation?
3. Laesst es manuelle und generierte Einkaufsbedarfe nebeneinander bestehen?
4. Unterstuetzt es Teil-Erfuellung statt nur ganz oder gar nicht?

## Vorlaeufige Entscheidung

Fuer `plangoreminisce` gilt ab jetzt fachlich:

1. `Meal Planning` ist Planungslogik
2. `Shopping` ist Beschaffungslogik
3. Shopping darf aus Meals entstehen, aber nicht auf Meals beschraenkt sein
4. Teilweise gekaufte Mengen sind ein gewuenschtes Ziel fuer den weiteren Ausbau
