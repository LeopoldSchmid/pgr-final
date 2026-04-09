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

## Auffaellige Abweichungen

### 1. Dokumentations-/Pruefpfad-Klarstellung

1. Die globale Rezeptbibliothek liegt unter `/en/recipes`
2. Der Pfad `/en/recipe_library` ist kein echter Frontend-Pfad
3. Das war beim ersten Smoke-Versuch ein Testfehler, kein Produktfehler

### 2. Mobile TLS-/Zertifikatsverhalten

1. Auf Laptop ist Staging erreichbar
2. Auf mindestens einem Handy gab es TLS-/Browser-Fehler
3. Das ist aktuell nicht als App-Blocker bewertet, sondern als separates Infrastrukturthema geparkt

## Noch nicht in diesem Smoke verifiziert

Diese Punkte bleiben offen und muessen in weiteren Durchgaengen geprueft werden:

1. Sign-out
2. Registrierung auf Staging
3. Einladung erstellen und annehmen
4. Meal Plan tatsaechlich anlegen, aendern, loeschen
5. Shopping List aus Meal Plan generieren
6. Rezept in Trip kopieren oder neu anlegen
7. Memories-/Attachment-Upload auf Staging
8. iPhone-/mobile Upload-Verhalten

## Vorlaeufiges Urteil

Kein akuter Deploy- oder Boot-Blocker mehr sichtbar.

Der aktuelle Staging-Stand ist technisch deutlich stabiler als zu Beginn dieser Runde:

1. Auth funktioniert
2. Trip-Kontext funktioniert
3. zentrale kontextabhaengige Screens laden
4. mindestens ein echter Schreibfluss funktioniert produktionsnah

Die naechsten echten Risikobloecke sind jetzt:

1. Einladungen
2. Meal Planning plus Shopping-Generierung
3. Upload-/Mobile-Flows
