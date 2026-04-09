# Delivery Standards

Stand: 2026-04-09

## Ziel

Dieses Dokument definiert den Mindeststandard fuer neue Arbeit in `plangoreminisce`.
Es soll verhindern, dass Features, Tests und Dokumentation wieder auseinanderlaufen.

## Pflicht fuer jedes relevante Arbeitspaket

1. Code fuer die beabsichtigte Verhaltensaenderung.
2. Tests fuer geaendertes Verhalten.
3. Dokumentationsupdate, wenn Verhalten, Architektur, Betrieb oder Scope betroffen sind.

## Test-Erwartungen

1. Domain-/Backend-Aenderungen:
   - Rails-Tests anpassen oder ergaenzen.
2. UI-/Flow-Aenderungen:
   - mindestens einen passenden Rails-Systemtest oder eine Playwright-Spec ergaenzen.
3. Mobile-kritische Aenderungen:
   - mobile Auswirkung explizit mitpruefen oder die Luecke dokumentieren.
4. Nicht versuchen, die komplette UI auf einmal rueckwirkend abzusichern.
   - Testabdeckung wird inkrementell am veraenderten Flow aufgebaut.

## Test-Baseline vor groesseren Abschluessen

Mindestens:
```bash
PARALLEL_WORKERS=1 bin/rails test
```

Wenn UI oder Browser-Flows betroffen sind, zusaetzlich:
```bash
bin/rails test test/system
npx playwright test tests/<betroffene-spec>.spec.ts --project=chromium
```

## Playwright- und Systemtest-Regeln

1. Fuer kritische Interaktionen bevorzugt stabile Selektoren.
2. `data-testid` gezielt dort einsetzen, wo Copy, Layout oder Icon-only Controls Tests sonst fragil machen.
3. In mehrsprachigen Screens nicht nur auf sichtbaren Text vertrauen, wenn die Semantik stabiler ueber Rolle, Label oder Test-ID ausdrueckbar ist.
4. Besonders absichern:
   - primary actions
   - Modal-Open/Close
   - Navigation-Trigger
   - wiederholte Row-Aktionen
   - mobile Upload- und Formularpfade

## Linting und statische Checks

Dieses Projekt hat bereits:
1. `rubocop-rails-omakase`
2. `brakeman`

Standard-Kommandos:
```bash
bundle exec rubocop
bundle exec brakeman
```

Regel:
1. RuboCop wird als Standard-Linter genutzt, nicht als optionales Extra.
2. Brakeman wird fuer sicherheitsrelevante Aenderungen mitgeprueft.
3. Wenn ein neuer Cop oder Stilkonflikt echten Produktnutzen behindert, wird das bewusst entschieden und dokumentiert, statt zufaellig ignoriert.

## Dokumentationsregeln

1. Die aktuelle Dokumentationshierarchie ist:
   - `documentation/stabilization_plan.md`
   - `documentation/status_quo.md`
   - `documentation/priorities.md`
   - `documentation/testing.md`
   - `documentation/delivery_standards.md`
   - `documentation/decision_log.md`
2. Wenn eine Aenderung diese Realitaet beeinflusst, muessen die betroffenen Dokumente aktualisiert werden.
3. Historische oder widerspruechliche Dokumente werden entfernt, nicht mitgeschleppt.

## Entscheidungslog

Wenn eine Aenderung mindestens eine dieser Eigenschaften hat, kommt ein Eintrag in `documentation/decision_log.md` dazu:

1. fachlicher Richtungswechsel
2. Architektur- oder Datenmodellentscheidung
3. neue Betriebs-/Deploy-Regel
4. bewusster Tradeoff bei Tests, Sicherheit oder Scope

## Definition of Done

Ein Arbeitspaket ist erst dann fertig, wenn:

1. das gewollte Verhalten funktioniert
2. die betroffenen Tests gruen sind
3. Autorisierung und Scope explizit bedacht wurden
4. mobile Auswirkungen nicht ignoriert wurden
5. relevante Doku aktualisiert ist
6. kein bekannter regressiver Kernbruch offen bleibt, ohne dokumentiert zu sein
