# UI Review

Stand: 2026-04-09

## Zweck

Dieses Dokument sammelt die aktuell sichtbaren UI-/UX-Probleme von `plangoreminisce`, ohne direkt Designentscheidungen vorwegzunehmen.
Es ist bewusst ein Review-Dokument und kein Umsetzungsplan.

Die Leitfrage ist nicht "Wie soll es am Ende aussehen?", sondern:

1. Wo verliert die App heute Informationsdichte?
2. Wo ist der mobile Fluss unklar oder schwerfällig?
3. Wo konkurrieren Navigation, Inhalte und Aktionen miteinander?

## Review-Basis

1. Staging ist erreichbar:
   - `GET /` auf `https://staging.plangoreminisce.duzend.net` liefert `200`
   - `GET /up` liefert `200`
2. Review auf Basis der aktuellen Kernviews und Layouts:
   - [application.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/layouts/application.html.erb)
   - [top_bar.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/shared/_top_bar.html.erb)
   - [bottom_navigation.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/shared/_bottom_navigation.html.erb)
   - [home/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/home/index.html.erb)
   - [trip_switcher/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/trip_switcher/index.html.erb)
   - [trips/plan.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/trips/plan.html.erb)
   - [plans/meals.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/plans/meals.html.erb)
   - [memories/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/memories/index.html.erb)
   - [expenses/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/expenses/index.html.erb)

## Kernbefunde

### 1. Zu viel vertikaler Raum fuer zu wenig Information

Das staerkste Muster ist grosszuegige Card- und Container-Nutzung bei relativ wenig Inhalt pro Block.

Beispiele:
- [home/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/home/index.html.erb)
- [trips/plan.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/trips/plan.html.erb)
- [trip_switcher/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/trip_switcher/index.html.erb)

Folgen:
- Auf Mobile ist zu wenig Inhalt "above the fold".
- Nutzer muessen frueh scrollen, bevor sie den relevanten Arbeitsbereich erreichen.
- Die App wirkt luftiger als hilfreich.

### 2. Zu viele Navigationsebenen gleichzeitig

Aktuell konkurrieren mehrere Navigationsebenen:

1. Top-Bar mit Trip-Kontext
2. Secondary Navigation
3. Left Sidebar auf Desktop
4. Bottom Navigation auf Mobile
5. kontextuelle Seitenlinks innerhalb einzelner Screens

Zentrale Stellen:
- [application.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/layouts/application.html.erb)
- [top_bar.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/shared/_top_bar.html.erb)
- [bottom_navigation.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/shared/_bottom_navigation.html.erb)

Folgen:
- Der aktive Navigationskontext ist nicht immer auf einen Blick klar.
- Die Seiten wirken schnell "eingerahmt", bevor der eigentliche Inhalt beginnt.
- Auf Mobile geht wertvolle Hoehe an persistenten Chrome-Verbrauch verloren.

### 3. Startseite ist emotional, aber nicht arbeitsorientiert genug

Die Dashboard-Struktur auf [home/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/home/index.html.erb) ist freundlich, aber sehr kartenlastig und relativ breit gedacht.

Probleme:
- grosser Willkommensbereich mit wenig Nutzwert
- viele Sektionen mit aequivalentem Gewicht
- zu wenig Priorisierung auf "Was soll ich als Naechstes tun?"

Folgen:
- Die Seite fuehlt sich mehr wie eine Uebersicht als wie ein Einstieg in konkrete Arbeit an.
- Der erste handlungsrelevante Inhalt startet zu spaet.

### 4. Planung ist funktional reich, visuell aber zu gleichfoermig

Die Planungsseite [trips/plan.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/trips/plan.html.erb) zeigt viele Werkzeuge, aber fast alle als aehnliche Kacheln.

Probleme:
- nahezu jedes Tool hat dieselbe visuelle Prioritaet
- hoher Emoji-Anteil statt klarer Informationshierarchie
- "Series" wirkt wie totes oder schwaches Element
- die Progress-Zusammenfassung ist sinnvoll, aber gestalterisch vom restlichen Screen nicht klar getrennt

Folgen:
- Nutzer sehen viele Optionen, aber nicht, was fuer den aktuellen Trip wirklich wichtig ist
- Unfertige oder schwache Features stehen optisch fast gleichberechtigt neben Kernaktionen

### 5. Meal Planning ist fuer Desktop brauchbar, fuer Mobile zu dicht und modal-lastig

Die Wochenansicht in [plans/meals.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/plans/meals.html.erb) ist logisch, aber als mobile-first UI noch nicht gut genug.

Probleme:
- 7-Tage-Raster plus 4 Meal-Slots erzeugt sehr viele kleine Felder
- Add/Edit-Interaktion laeuft ueber viele einzelne Modals
- Leerzustand ist visuell recht schwach
- Navigation fuer Wochenwechsel und Inhalt konkurrieren im Header auf engem Raum

Folgen:
- Auf kleinen Screens entsteht schnell visuelle Kleinteiligkeit
- Planung fuehlt sich eher nach Tabellenpflege als nach alltagsnaher Nutzung an

### 6. Memories und Expenses zeigen Inhalt, aber mit zu wenig Verdichtung

Memories:
- [memories/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/memories/index.html.erb)

Expenses:
- [expenses/index.html.erb](/home/leo/dev/projects/plangoreminisce/app/views/expenses/index.html.erb)

Probleme:
- viel Innenabstand pro Karte
- wenig komprimierte Metadatenzeilen
- wenig visuelle Gruppierung zwischen primären und sekundären Informationen
- bei Expenses stehen Summary, Settlement und Liste relativ lose nebeneinander

Folgen:
- Die Screens sind lesbar, aber nicht besonders effizient
- gerade auf Mobile sinkt die wahrgenommene Informationsdichte deutlich

## Mobile-First-Besonderheiten

Diese Themen sind fuer die naechste Designrunde besonders relevant:

1. Die feste obere und untere Navigation verbraucht auf kleinen Screens spuerbar Platz.
2. Wichtige Kernscreens beginnen inhaltlich oft zu weit unten.
3. Raster- und Kartenlogik ist haeufig eher fuer Tablet/Desktop gedacht.
4. Upload-, Meal-Planning- und Trip-Kontext-Wechsel muessen mit moeglichst wenig Friktion funktionieren.

## Positive Aspekte

Der Stand ist nicht nur problematisch. Positiv ist:

1. Die App hat bereits eine erkennbare strukturelle Idee.
2. Trip-Kontext ist als zentrales Arbeitsmodell sichtbar.
3. Kernbereiche sind funktional relativ gut getrennt.
4. Die Screens sind konsistent genug, um jetzt bewusst ueber Verdichtung und Hierarchie nachzudenken.

## Noch keine Loesungen, aber klare Designfragen

Diese Fragen sollten die spaetere UI-Runde steuern:

1. Welche zwei bis drei Aktionen muessen pro Hauptscreen sofort sichtbar sein?
2. Welche Navigation ist wirklich persistent notwendig und welche nicht?
3. Wo brauchen wir Listen statt Karten?
4. Wo brauchen wir verdichtete Metadaten statt grosszuegiger Hero-/Header-Flaechen?
5. Welche Planungselemente muessen mobil wirklich als Raster erscheinen und welche besser als Liste oder Tagesansicht?
6. Welche unfertigen Features duerfen visuell heute noch gleich stark erscheinen wie Kernfunktionen?

## Vorlaeufiges Urteil

Das Hauptproblem ist aktuell nicht "haesslich", sondern "zu wenig fokussiert und zu wenig dicht".

Die App hat bereits viele Funktionen, praesentiert sie aber oft mit:

1. zu viel White Space
2. zu vielen gleich gewichteten Kacheln
3. zu viel Navigationschrome
4. zu wenig handlungsorientierter Priorisierung

Fuer die naechste Designrunde sollte daher nicht zuerst ueber Farben oder Stil gesprochen werden, sondern ueber:

1. Informationsdichte
2. mobile Priorisierung
3. Reduktion von Navigationskonkurrenz
4. klare Gewichtung pro Screen
