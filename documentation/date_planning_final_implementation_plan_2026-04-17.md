# Date Planning Final Implementation Plan

Stand: 2026-04-17

## Zweck

Dieses Dokument ist der verbindliche Umsetzungsplan fuer das komplette Date-Planning-Endsystem in `plangoreminisce`.

Es ersetzt eine v1/Teilloesung und definiert:

1. finalen Zielumfang
2. Architektur- und Produktregeln
3. Implementierungsbloecke mit Abhaengigkeiten
4. technische und fachliche Abnahmekriterien

## Verbindliche Leitentscheidungen

1. Kein Feature Flag. Deployment erst, wenn der gesamte Scope fertig und getestet ist.
2. `Trip start_date/end_date` duerfen nur durch den Trip Owner geaendert werden.
3. Datumsanpassungen am Trip laufen nur ueber einen expliziten Migrationsflow mit Impact-Preview.
4. Standard-Migrationsregel: betroffene Meals werden `unscheduled` statt geloescht.
5. Shopping-Logik folgt den Meal-Aenderungen per Cascade/Synchronisierung.
6. Date Planning unterstuetzt:
   - mehrere Optionen pro User
   - Diskussion pro Option
   - globale Verfuegbarkeiten
   - finalen Abstimmungsmodus
7. Finale Abstimmung ist Owner-konfigurierbar:
   - exakt eine Stimme pro aktivem Mitglied oder
   - mehrere Stimmen pro aktivem Mitglied (optional begrenzt)
8. Diskussionen werden als generische, verteilte Threads umgesetzt:
   - dezentral am Objekt (z. B. Date Proposal)
   - zentral aggregiert in einer Forumsansicht mit Sektionen
9. Kalenderbasis wird aus `hausl` uebernommen, aber in `plangoreminisce` horizontal statt vertikal umgesetzt.
10. Bestehende FullCalendar-Abhaengigkeit wird final entfernt.

## Zielbild (Endzustand)

## Date Planning Domain

1. Nutzer koennen mehrere Datumsoptionen vorschlagen.
2. Datumsoptionen koennen diskutiert und bewertet werden.
3. Bewertungs-/Signaltypen pro Option:
   - `cannot`
   - `difficult`
   - `possible`
   - `preferred`
4. Globale User-Verfuegbarkeiten koennen trip-uebergreifend gepflegt werden und in Trips einbezogen werden.
5. Owner kann aus Signalen und Diskussion in den finalen Abstimmungsmodus wechseln.

## Final Vote Domain

1. Owner startet eine finale Abstimmungsrunde mit Shortlist.
2. Voting-Regeln kommen aus Owner-Konfiguration:
   - `single_choice_required`
   - `multi_choice_allowed` (optional `max_votes_per_member`)
3. Optionales `abstain`.
4. Runde hat Deadline und optionales Quorum.
5. Kein klarer Sieger:
   - Tie oder Quorum nicht erreicht
   - Owner-Entscheid mit Pflichtbegruendung
6. Nach finaler Entscheidung: Uebernahme auf Trip-Datum via Owner-Migrationsflow.

## Discussion Domain (zentral + dezentral)

1. Threads sind polymorph an Objekte gebunden (z. B. `Trip`, `DateProposal`, spaeter `MealPlan`, `LocationProposal`).
2. Threads besitzen eine `forum_section` (analog Navigationsbereichen).
3. Jede Objektansicht zeigt lokale Diskussion fuer das Objekt.
4. Zentrale Forumsansicht zeigt aggregierte Threads ueber Sektionen und Objekte.
5. Jeder Thread verlinkt zur Kontextseite.

## Trip Date Migration Domain

1. Nur Owner darf starten.
2. Vor Commit wird Impact-Preview erzeugt.
3. Standardstrategie:
   - Meals ausserhalb Range -> `unscheduled`
   - Shopping Requirements via Sync auf `outdated` oder `detached`, ohne stilles Datenvernichten
4. Optionalstrategien:
   - harte Loeschung betroffener Daten
   - zeitliche Verschiebung (Delta-Shift)
5. Jede Datumsmigration wird auditiert und ist undo-faehig.

## Kalender/UI Domain

1. FullCalendar raus.
2. Hausl-Monatsdarstellung als Basis, horizontal optimiert fuer Monatsnavigation.
3. Scroll-Verhalten:
   - horizontales Monats-Snapping
   - Monatswechsel ueber Navigation + Touch-Scroll
4. Date-Optionen und Verfuegbarkeiten als ueberlagerte Lanes/Marker im Monatsraster.

## Datenmodell-Target

## Neue/erweiterte Tabellen

1. `trips`
   - `date_planning_status` (`collecting`, `discussing`, `final_vote`, `finalized`)
   - `date_locked_at`
   - `date_locked_by_id`
2. `trip_date_planning_settings`
   - `trip_id`
   - `final_vote_rule` (`single_choice_required`, `multi_choice_allowed`)
   - `allow_abstain` (boolean)
   - `max_votes_per_member` (nullable, nur bei multi choice)
   - `quorum_percent` (nullable)
   - `tie_break_strategy` (z. B. `owner_decides`)
3. `date_proposals` (Erweiterungen)
   - `status` (`open`, `selected`, `withdrawn`, `archived`)
   - `selected_at`
   - `selected_by_id`
4. `date_proposal_signals` (neu)
   - `date_proposal_id`
   - `user_id`
   - `signal_type` (`cannot`, `difficult`, `possible`, `preferred`)
   - `note`
   - unique (`date_proposal_id`, `user_id`)
5. `date_proposal_final_vote_rounds` (neu)
   - `trip_id`
   - `state` (`open`, `closed`, `resolved`)
   - `deadline_at`
   - `quorum_percent_snapshot`
   - `final_vote_rule_snapshot`
   - `allow_abstain_snapshot`
   - `max_votes_per_member_snapshot`
   - `started_by_id`
   - `resolved_by_id`
   - `resolution_reason`
6. `date_proposal_final_votes` (neu)
   - `round_id`
   - `date_proposal_id`
   - `user_id`
   - `abstain` (boolean)
   - unique-Regeln entsprechend Voting-Modus
7. `discussion_posts` (Erweiterungen)
   - `discussable_type`
   - `discussable_id`
   - `forum_section`
   - `status` (`open`, `resolved`)
8. `meal_plans` (Erweiterungen)
   - `date` wird optional
   - `unscheduled_reason`
   - `unscheduled_at`
   - `previous_date`
9. `trip_date_changes` (neu, Audit)
   - `trip_id`
   - `changed_by_id`
   - `previous_start_date`, `previous_end_date`
   - `new_start_date`, `new_end_date`
   - `migration_strategy`
   - `impact_snapshot` (json)
   - `applied_at`
   - `undo_token`

## Migration bestehender Daten

1. `date_proposal_votes` -> `date_proposal_signals`
   - `yes` => `preferred`
   - `maybe` => `possible`
   - `no` => `cannot`
2. Bestehende `discussion_posts` werden auf `discussable=Trip` gemappt.
3. Bestehende Meals behalten Datum; nur neue Migrationsfaelle erzeugen `unscheduled`.

## Berechtigungsmodell

1. Owner:
   - darf Trip-Datum final setzen/aendern
   - darf Final Vote starten/schliessen/entscheiden
   - darf Voting-Regeln konfigurieren
2. Admin/Member:
   - duerfen Vorschlaege erstellen
   - duerfen Signale setzen
   - duerfen diskutieren
   - duerfen final abstimmen
3. Guest:
   - read-only (kein Vorschlag, kein Signal, keine finale Stimme)
4. Serverseitige Durchsetzung in Controllern/Policies ist Pflicht; UI allein reicht nicht.

## Technische Kernkomponenten

1. `DatePlanning::ScoreService`
   - Aggregiert Signale pro Option
   - erzeugt Ranking/Conflicts
2. `DatePlanning::FinalVoteService`
   - startet und validiert Runden
   - setzt Regeln durch
   - ermittelt Ergebnis/Tie/Quorum
3. `DatePlanning::FinalizeTripDateService`
   - uebernimmt gewaehlte Option auf Trip
   - triggert Migrationsflow
4. `TripDates::ImpactPreviewService`
   - listet Meal/Shopping-Auswirkungen
5. `TripDates::ApplyChangeService`
   - fuehrt Strategie aus (`unschedule`, `delete`, `shift`)
   - erzeugt Audit
6. `TripDates::UndoChangeService`
   - rollback ueber Snapshot/Undo-Token
7. `Forum::ThreadQueryService`
   - aggregiert lokale Threads in zentrale Sektionenansicht

## API- und Routing-Target

1. `trip_date_planning_settings`:
   - `GET/PUT`
2. `date_proposals`:
   - `index/create/update/destroy`
   - `finalize_candidate` (Owner)
3. `date_proposal_signals`:
   - `upsert/destroy`
4. `date_proposal_final_vote_rounds`:
   - `create` (Owner startet)
   - `close` (Owner/Deadline)
   - `resolve` (Owner bei Tie/kein Sieger)
5. `date_proposal_final_votes`:
   - `create/update/destroy` mit Regelvalidierung
6. `trip_date_changes`:
   - `preview`
   - `apply`
   - `undo`
7. `forums`:
   - zentrale Indexansicht mit Section/Object-Filtern
8. `discussion_posts`:
   - polymorphes create/update/destroy fuer lokale Objektseiten

## UI-Struktur (final)

1. `Trip Dates` als primare Date-Planning-Oberflaeche.
2. Drei gekoppelte Bereiche:
   - horizontaler Monatskalender
   - Optionenliste mit Ranking/Conflict-Hinweisen
   - lokale Diskussion zum selektierten Objekt
3. Zentrales Forum als eigene Seite mit Sektionen:
   - `general`
   - `date_planning`
   - `date_options`
   - `meals`
   - `shopping`
   - spaeter `locations`
4. Owner-only Controls klar sichtbar:
   - Voting-Regeln
   - Final Vote starten
   - Trip-Datum finalisieren
   - Trip-Datum aendern (Migrationsflow)

## Implementierungsbloecke (verbindliche Reihenfolge)

## Block A - Foundations und Schema

Ziel:
1. Datenstrukturen fuer Signale, Final Vote, Audit, polymorphe Diskussionen, unscheduled meals schaffen.

Scope:
1. Alle Migrationen aus Datenmodell-Target.
2. Basismodelle + Validierungen + Indizes.
3. Datenmigration `date_proposal_votes -> date_proposal_signals`.

Exit:
1. Schema migriert.
2. Model-Tests fuer Validierungen/Unique-Regeln gruen.

## Block B - Berechtigungen und Guard Rails

Ziel:
1. Owner-only-Datumsregeln und Rollenrechte serverseitig fixieren.

Scope:
1. Authorization fuer Date Planning, Final Vote, Trip Date Change.
2. Harter Stop fuer direkte Trip-Date-Aenderung ausserhalb Owner-Migrationsflow.

Exit:
1. Request/Controller-Tests fuer alle Rollen gruen.

## Block C - Date Planning Core (Proposals + Signals + Score)

Ziel:
1. Vollstaendiger Vorschlags- und Signalflow inkl. Ranking.

Scope:
1. Proposal CRUD.
2. Signal upsert/remove.
3. ScoreService + Konfliktindikatoren.

Exit:
1. API + UI fuer Proposals/Signals produktionsreif.
2. Scoring-Tests inkl. Edge Cases gruen.

## Block D - Final Vote (konfigurierbar)

Ziel:
1. Owner-konfigurierter finaler Abstimmungsprozess.

Scope:
1. Settings-UI/Backend.
2. Round lifecycle (`create`, `vote`, `close`, `resolve`).
3. Regelpruefung:
   - single choice exakt 1 Stimme (wenn `allow_abstain=false`)
   - multi choice mit optionalem Maximum
4. Quorum/Deadline/Tie-Verhalten.

Exit:
1. End-to-End-Flow fuer beide Voting-Regeln getestet.
2. Owner-Override mit Pflichtbegruendung getestet.

## Block E - Polymorphe Diskussionen + zentrales Forum

Ziel:
1. Dezentrale Objekt-Diskussion und zentrale Aggregation in einem System.

Scope:
1. `discussion_posts` auf polymorphes Modell erweitern.
2. Lokale Thread-Einbindung in Date Planning.
3. Forum-Index mit Sektionen, Filtern, Deep-Links.
4. Datenmigration bestehender Threads.

Exit:
1. Diskussionen lokal und zentral konsistent.
2. Migration ohne Thread-Verlust.

## Block F - Horizontaler Kalender (Hausl-Transfer)

Ziel:
1. Neuer monatlicher Date-Planning-Kalender ohne FullCalendar.

Scope:
1. Monatsraster/Lane-Layout auf Basis hausl.
2. Horizontales Scroll-Snap.
3. Navigation + Jump-to-Month.
4. Event-Layer fuer Proposal + Signal + globale Availability.

Exit:
1. Mobile und Desktop verhalten sich stabil.
2. Performance und Bedienbarkeit fuer mehrere Monate validiert.

## Block G - Trip Date Finalisierung + Impact Preview

Ziel:
1. Option in Trip-Datum ueberfuehren mit sicherem Preview.

Scope:
1. Preview-Service mit klarer Impact-Liste.
2. Finalize-Service vom Sieger/Owner-Entscheid.
3. Audit-Eintrag fuer jede Aenderung.

Exit:
1. Keine blinde Datumsuebernahme mehr.
2. Vollstaendige Nachvollziehbarkeit im Audit.

## Block H - Meal Migration zu unscheduled

Ziel:
1. Datumsmigration ohne Meal-Datenverlust.

Scope:
1. `meal_plans.date` optional.
2. UI-Bereich fuer `unscheduled meals`.
3. Re-schedule Aktionen.

Exit:
1. Bei Datumsverkuerzung/verschiebung gehen Meals nicht verloren.
2. Meal-UI deckt geplante + ungeplante Meals ab.

## Block I - Shopping Cascade und Konsistenz

Ziel:
1. Shopping bleibt korrekt bei Meal/Date-Migrationen.

Scope:
1. RequirementBuilder ignoriert unscheduled meals fuer aktive Tagesbedarfe.
2. Synchronizer behandelt entfernte Quellen robust (`outdated`/`detached`).
3. Undo-Kompatibilitaet mit Date Change Audit.

Exit:
1. Shopping-Regressionen fuer Date-Migrationen bestanden.

## Block J - FullCalendar Removal und Bereinigung

Ziel:
1. Alte Kalenderpfade komplett entfernen.

Scope:
1. Importmap pins fuer FullCalendar entfernen.
2. alte Controller-/View-Reste entfernen oder umhaengen.
3. CSS/JS-Bereinigung.

Exit:
1. Kein FullCalendar/Skypack mehr im Runtime-Pfad.

## Block K - Testhaerte, Bugfix, Abnahme

Ziel:
1. Releasefaehiger Gesamtstand.

Scope:
1. Model-, Controller-, Request-, Systemtests.
2. E2E fuer Hauptfluesse:
   - proposal + signal + discussion
   - final vote single/multi
   - owner finalize + migration preview/apply/undo
   - meal unscheduled + re-schedule
   - shopping cascade
   - forum aggregation + deep links
3. Bugfix-Runde und Dokumentationsabgleich.

Exit:
1. Alle Tests gruen.
2. Abnahmekriterien erfuellt.

## Abnahmekriterien (Release Gate)

1. Date Planning ist ohne FullCalendar voll nutzbar.
2. Owner-only Regeln fuer Trip-Datum und Voting-Settings sind serverseitig erzwungen.
3. Finale Abstimmung funktioniert fuer:
   - exakt eine Stimme
   - mehrere Stimmen (konfiguriert)
4. Tie- und Quorum-Faelle sind fachlich korrekt aufloesbar.
5. Objekt-Diskussionen funktionieren lokal und zentral im Forum.
6. Trip-Datumsaenderung hat Preview, Audit und Undo.
7. Meal-Daten bleiben bei Datumsaenderungen erhalten (`unscheduled` statt stiller Verlust).
8. Shopping bleibt nach Migration konsistent.
9. Alle definierten Test-Suiten sind gruen.

## Risiken und Gegenmassnahmen

1. Risiko: grosse Refactor-Breite (Date + Forum + Meal + Shopping).
   - Gegenmassnahme: strikte Block-Reihenfolge, keine Scope-Drift innerhalb Blocks.
2. Risiko: versteckte Abhaengigkeiten in Meal/Shopping.
   - Gegenmassnahme: fruehe Impact- und Regressionstests ab Block H/I.
3. Risiko: UI-Komplexitaet bei horizontalem Kalender.
   - Gegenmassnahme: hausl-Lane-Prinzip uebernehmen, aber Scroll-Mechanik gezielt neu implementieren.

## Nicht-Ziele fuer diese Umsetzung

1. Kein partieller Produktionsstart.
2. Kein zweites paralleles Date-Planning-System.
3. Kein Location-Planning-Feature in dieser Iteration (nur Diskussion-Architektur dafuer vorbereiten).

## Arbeitsregel

Implementierung startet erst nach explizitem Go auf dieses Dokument.

