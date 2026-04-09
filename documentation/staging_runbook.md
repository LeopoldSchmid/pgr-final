# Staging Runbook

Stand: 2026-04-09

## Zweck

Dieses Dokument beschreibt den praktischen Ablauf fuer den ersten echten Staging-Deploy und die direkt anschliessende Verifikation.

Es ist bewusst kurz und operativ.

## Vor dem ersten Deploy

1. Sicherstellen, dass die lokalen Projekt-Binstubs verwendet werden:
   ```bash
   bin/rails runner 'puts "boot-ok"'
   bin/kamal version
   ```
2. Deploy-Umgebung laden:
   ```bash
   cp .kamal/deploy.env.example .kamal/deploy.env
   set -a; source .kamal/deploy.env; set +a
   ```
   Alternativ wie in `zapfe-rails` direkt ueber den Projekt-Wrapper:
   ```bash
   bin/kamal_with_env config -d staging
   ```
3. Pflichtvariablen gesetzt pruefen:
   ```bash
   test -n "$KAMAL_REGISTRY_PASSWORD" && echo registry-ok
   test -n "$RAILS_MASTER_KEY" && echo master-key-ok
   ```
4. Lokale Test-Baseline laufen lassen:
   ```bash
   PARALLEL_WORKERS=1 bin/rails test
   ```

## Staging-Preflight

1. Zielkonfiguration ansehen:
   ```bash
   bin/kamal_with_env config -d staging
   ```
2. Wenn der Server noch nie fuer Staging eingerichtet wurde:
   ```bash
   bin/kamal_with_env setup -d staging
   ```
3. Wenn Staging bereits existiert:
   ```bash
   bin/kamal_with_env deploy -d staging
   ```

## Unmittelbar nach dem Deploy

1. Status pruefen:
   ```bash
   bin/kamal_with_env details -d staging
   ```
2. Logs ansehen:
   ```bash
   bin/kamal_with_env logs -d staging
   ```
3. Falls noetig Rails-Konsole:
   ```bash
   bin/kamal_with_env console -d staging
   ```

## Pflichtverifikation

Nach jedem erfolgreichen Deploy:

1. [staging_smoke_checklist.md](/home/leo/dev/projects/plangoreminisce/documentation/staging_smoke_checklist.md) abarbeiten
2. Ergebnis dokumentieren:
   - Datum
   - Commit
   - Browser/Geraet
   - Blocker
   - Nicht-Blocker
   - Folgeaufgaben

## Wenn etwas schiefgeht

1. Erst Logs lesen:
   ```bash
   bin/kamal_with_env logs -d staging
   ```
2. Danach Container-/Proxy-Status:
   ```bash
   bin/kamal_with_env details -d staging
   ```
3. Nur wenn der neue Stand klar schlechter ist und Ursache nicht schnell behebbar:
   ```bash
   bin/kamal_with_env rollback -d staging
   ```

## Bekannte Hinweise

1. `bin/kamal` ist jetzt auf dieselbe Ruby-Toolchain wie die restlichen Projekt-Binstubs gezogen.
2. Eine verbleibende `VIPS`-Warnung ist aktuell kein bekannter Blocker fuer die verifizierten App-Fluesse.
3. Produktion bleibt bis auf Weiteres unberuehrt.
