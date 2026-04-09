# Staging Smoke Results 2026-04-09

Stand: 2026-04-09
Deploy-Stand: `b8c3bde` bis `9e2db8c` verifiziert, Staging erfolgreich erreichbar
Umgebung: `https://staging.plangoreminisce.duzend.net`

## Gepruefte Baseline

1. `GET /` liefert `200`
2. `GET /up` liefert `200`
3. Login mit Seed-User funktioniert
4. Trip-Kontext kann gesetzt werden
5. wichtige kontextabhaengige Seiten laden mit aktiver Session
6. Expense-Erfassung funktioniert als echter Schreibfluss
7. Einladungsannahme fuer neuen Nutzer funktioniert
8. Meal Planning funktioniert als echter Schreibfluss
9. Shopping-Generierung aus Meal Plan funktioniert grundsaetzlich
10. Attachment-Upload funktioniert als echter Schreibfluss

## Verwendete Testzugangsdaten

1. `test@example.com` / `password123`

## Verifizierte Flows

### A. Basis und Auth

1. `POST /en/session` mit Seed-User liefert Redirect nach `/en`
2. Session-Cookie wird gesetzt
3. authentifizierte Seiten sind anschliessend erreichbar

### B. Trip-Kontext

1. `GET /en/select_trip` liefert `200`
2. `POST /en/switch_trip?trip_id=1` mit Session und CSRF liefert Redirect auf `/en/trips/1`
3. kontextbasierte Seiten laden danach erfolgreich

### C. Kontextabhaengige Kernseiten mit aktivem Trip

1. `GET /en/plans/meals` -> `200`
2. `GET /en/expenses` -> `200`
3. `GET /en/memories` -> `200`
4. `GET /en/trips/1/shopping_lists` -> `200`

Hinweis:
1. `GET /en/trips/1/plan` liefert `302`
2. Das ist aktuell erwartbar, weil [TripsController](/home/leo/dev/projects/plangoreminisce/app/controllers/trips_controller.rb) die alte Plan-Route auf den neuen Trip-Hub-Kontext umleitet

### D. Echter Schreibfluss

1. Expense wurde auf Staging erfolgreich angelegt
2. `POST /en/expenses` lieferte Redirect auf `/en/expenses`
3. der neu angelegte Eintrag war anschliessend in der Expense-Liste sichtbar

### E. Einladungen

1. Trip-Owner kann Einladung auf Staging erstellen
2. Einladungslink kann als Gast geoeffnet werden
3. Neuer Nutzer wird in Registrierung gefuehrt und kann Einladung annehmen
4. nach Abschluss landet der eingeladene Nutzer im eingeladenen Trip
5. der Eintrag erscheint anschliessend im akzeptierten Einladungszustand

### F. Meal Planning und Shopping

1. Ein neues Rezept konnte direkt im Trip angelegt werden
2. Ein Meal konnte auf Staging erfolgreich geplant werden
3. der geplante Recipe-Name war anschliessend im Meal-Plan sichtbar
4. `POST /en/trips/1/shopping_lists/1/generate_from_meal_plan` funktionierte mit Redirect zur aktuellen Liste
5. die Shopping-Liste zeigte anschliessend generierte Positionen aus dem Meal Plan

### G. Memories und Upload

1. Ein Attachment konnte erfolgreich hochgeladen werden
2. der Upload lieferte den Success-Flash `Attachment was successfully uploaded.`
3. der neue Eintrag war anschliessend im globalen Memories-Feed sichtbar

## Auffaellige Abweichungen

### 1. Dokumentations-/Pruefpfad-Klarstellung

1. Die globale Rezeptbibliothek liegt unter `/en/recipes`
2. Der Pfad `/en/recipe_library` ist kein echter Frontend-Pfad
3. Das war beim ersten Smoke-Versuch ein Testfehler, kein Produktfehler

### 2. Mobile TLS-/Zertifikatsverhalten

1. Auf Laptop ist Staging erreichbar
2. Auf mindestens einem Handy gab es TLS-/Browser-Fehler
3. Das ist aktuell nicht als App-Blocker bewertet, sondern als separates Infrastrukturthema geparkt

### 3. Shopping-Generierung wirkt fachlich noch unvollstaendig

1. Im Smoke-Rezept wurden `Tomatoes` und `Salt` angelegt
2. Nach `generate_from_meal_plan` erschien `Tomatoes` in der Shopping-Liste
3. `Salt` erschien im selben Lauf nicht sichtbar in der Shopping-Liste
4. Das deutet auf eine Luecke in Ingredient-Parsing oder Shopping-Generierung hin, nicht auf einen kompletten Flow-Ausfall

## Noch nicht in diesem Smoke verifiziert

Diese Punkte bleiben offen und muessen in weiteren Durchgaengen geprueft werden:

1. Sign-out
2. freie Registrierung auf Staging ohne Einladung
3. Einladung fuer bestehenden Nutzer
4. Meal Plan aendern und loeschen
5. Rezept aus globaler Bibliothek in den Trip kopieren
6. direkter Sichtbarkeitscheck neuer Attachments im Trip-Plan selbst
7. iPhone-/mobile Upload-Verhalten
8. Expense bearbeiten, duplizieren und loeschen
9. Sign-out plus erneuter Login-Zyklus

## Vorlaeufiges Urteil

Kein akuter Deploy- oder Boot-Blocker mehr sichtbar.

Der aktuelle Staging-Stand ist technisch deutlich stabiler als zu Beginn dieser Runde:

1. Auth funktioniert
2. Trip-Kontext funktioniert
3. zentrale kontextabhaengige Screens laden
4. mindestens ein echter Schreibfluss funktioniert produktionsnah
5. Einladungen funktionieren fuer neue Nutzer
6. Meal Planning und Shopping funktionieren mindestens im Grundfluss
7. Attachment-Upload funktioniert serverseitig und ist im Memories-Feed sichtbar

Die naechsten echten Risikobloecke sind jetzt:

1. mobile Upload-/Kameraflows
2. fachliche Konsistenz der Shopping-Generierung
3. verbleibende Schreibfluesse rund um Expenses und Meals
