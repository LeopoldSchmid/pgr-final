# Staging Smoke Checklist

Stand: 2026-04-09

## Zweck

Diese Checkliste ist die operative Minimalpruefung fuer `staging.plangoreminisce.duzend.net`.
Sie soll vor relevanten Staging-Freigaben und vor dem ersten Freundes-Test konsequent abgearbeitet werden.

Sie ersetzt keine tieferen Reviews, aber sie verhindert, dass wir bekannte Kernfluesse wieder nur gefuehlt statt konkret pruefen.

## Voraussetzungen

1. Staging ist erfolgreich deployt.
2. `APP_HOST`, Mail, Storage und `RAILS_MASTER_KEY` sind korrekt gesetzt.
3. Die lokale technische Baseline ist gruen:
   ```bash
   PARALLEL_WORKERS=1 bin/rails test
   ```
4. Fuer browsernahe Kernfluesse ist mindestens der relevante Systemtest oder Playwright-Test gruen.

## Release Gate

Ein Staging-Stand gilt nur dann als pruefbar, wenn diese beiden Bedingungen gleichzeitig gelten:

1. Automatisierte Baseline ist gruen.
2. Die manuelle Smoke-Checkliste unten ist ohne Blocker durchgelaufen.

## Automatisierte Baseline

Mindestens:
```bash
PARALLEL_WORKERS=1 bin/rails test
```

Wenn browsernahe Flows betroffen sind, zusaetzlich:
```bash
bin/rails test test/system
```

Wenn vorhandene Playwright-Smokes oder lokale Browser-Audits betroffen sind:
```bash
npx playwright test
```

## Manuelle Kernpruefung

### A. Basis und Einstieg

1. Staging-Startseite laedt ohne 500er.
2. Registrierung und Login-Seite laden korrekt.
3. Session bleibt nach Login stabil.
4. Sign-out funktioniert.

### B. Trip-Kontext

1. Trip-Wechsel ueber den Trip-Switcher funktioniert.
2. Nach dem Wechsel zeigen `Trip`, `Plans`, `Memories` und `Expenses` denselben aktiven Trip-Kontext.
3. Kontextbasierte Seiten ohne aktiven Trip leiten nachvollziehbar weiter.

### C. Trip und Planung

1. Neuer Trip kann angelegt werden.
2. Trip-Overview, Details und Participants laden.
3. Meal Planning laedt.
4. Ein Meal kann geplant, geaendert und geloescht werden.
5. Shopping List kann aus dem Meal Plan erzeugt werden.

### D. Rezepte

1. Rezeptbibliothek laedt.
2. Ein Rezept kann in den Trip kopiert oder neu angelegt werden.
3. Das Rezept steht anschliessend im relevanten Planungsfluss zur Verfuegung.

### E. Expenses

1. Expense-Liste laedt im aktiven Trip.
2. Neue Expense mit equal split anlegen.
3. Expense bearbeiten.
4. Expense duplizieren oder loeschen.
5. `By person`, `By category`, `Settle up`, `Summary` laden ohne Fehler.

### F. Memories und Upload

1. Memories-Feed laedt im Trip-Kontext.
2. Globaler Memories-Feed laedt ohne Template-Fehler.
3. Ein Journal- oder Foto-/Attachment-Eintrag kann angelegt werden.
4. Attachment-Upload funktioniert fuer mindestens ein Bild.
5. Upload funktioniert auf mobilem Browser bzw. iPhone-vergleichbarer Umgebung.

### G. Einladungen

1. Trip-Owner kann Einladung erstellen.
2. Einladung per Link oeffnen funktioniert.
3. Bestehender Nutzer wird sauber in Login -> Annahme gefuehrt.
4. Neuer Nutzer wird sauber in Registrierung -> Annahme gefuehrt.
5. Falscher eingeloggter Nutzer wird klar abgefangen.

### H. Mobile-First-Kernpruefung

Diese Punkte sind Pflicht und duerfen nicht nur auf Desktop geprueft werden:

1. Login
2. Trip-Wechsel
3. Meal Planning
4. Expense-Erfassung
5. Foto-/Attachment-Upload

## Ergebnisdokumentation

Nach jedem echten Staging-Smoke kurz festhalten:

1. Datum
2. Commit oder Deploy-Stand
3. Getestete Browser/Geraete
4. Blocker
5. Nicht-Blocker
6. Offene Folgeaufgaben

## Blocker-Regel

Ein Staging-Stand ist kein Kandidat fuer externen Testbetrieb, wenn einer dieser Punkte fehlschlaegt:

1. Login / Session / Sign-out
2. Trip-Kontext
3. Meal Planning
4. Shopping-Generierung
5. Expense-Erfassung
6. Einladung annehmen
7. mobiler Foto-Upload

## Hinweise

1. `bin/dev` ist lokaler Komfort und keine Release-Wahrheit.
2. Staging ist die Quelle fuer reale Betriebspruefung, nicht die lokale Maschine.
3. Diese Checkliste darf erweitert werden, aber nicht verwässert werden.
