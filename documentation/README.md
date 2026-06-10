# Documentation

Stand: 2026-04-17

## Start Here

1. [stabilization_plan.md](./stabilization_plan.md)
   - Operatives Referenzdokument fuer die naechsten Schritte.
   - Definiert Nicht-Ziele, Arbeitsstraenge, offene Fragen und Reihenfolge.
2. [status_quo.md](./status_quo.md)
   - Kompakter Ist-Zustand von Produkt, Technik und Deploy-Basis.
3. [priorities.md](./priorities.md)
   - Konkrete `must / should / could`-Priorisierung und Arbeitsreihenfolge.
4. [testing.md](./testing.md)
   - Lokale Test-Kommandos, Playwright-Setup und Rails-Testbasis.
5. [staging_smoke_checklist.md](./staging_smoke_checklist.md)
   - Operative Staging- und Beta-Smoke-Checkliste fuer Kernfluesse.
6. [staging_runbook.md](./staging_runbook.md)
   - Praktischer Ablauf fuer den ersten echten Staging-Deploy.
7. [delivery_standards.md](./delivery_standards.md)
   - Verbindlicher Mindeststandard fuer Tests, Doku und Abschlusskriterien.
8. [decision_log.md](./decision_log.md)
   - Kurze dokumentierte Architektur- und Produktentscheidungen.
9. [ui_review.md](./ui_review.md)
   - Review der aktuellen Informationsdichte, Navigationskonkurrenz und Mobile-Fitness.
10. [staging_smoke_results_2026-04-09.md](./staging_smoke_results_2026-04-09.md)
   - Erste dokumentierte Smoke-Ergebnisse auf dem laufenden Staging-System.
11. [meal_planning_and_shopping_target_model.md](./meal_planning_and_shopping_target_model.md)
   - Fachliches Zielmodell fuer die weitere Entwicklung von `Meal Planning` und `Shopping`.
12. [shopping_workflow_concept.md](./shopping_workflow_concept.md)
   - Praezisiert Multi-List-Shopping, Pflegeansicht vs. Einkaufsansicht und manuelle Synchronisierung mit dem Meal Plan.
13. [shopping_technical_architecture.md](./shopping_technical_architecture.md)
   - Technisches Zielmodell fuer Requirements, Listen, Assignments, Sync und die stufenweise Neuimplementierung.
14. [shopping_ui_structure.md](./shopping_ui_structure.md)
   - UI-Struktur fuer den finalen Flow `Meal Plan -> Shopping Plan -> Shopping List` auf Basis der aktuellen Mockups.
15. [meal_plan_finalization_spec_2026-04-17.md](./meal_plan_finalization_spec_2026-04-17.md)
   - Verbindliche Spezifikation fuer die finale Meal-Plan-UX und die fachliche Integration in Shopping Plan und Shopping List.
16. [date_planning_final_implementation_plan_2026-04-17.md](./date_planning_final_implementation_plan_2026-04-17.md)
   - Verbindlicher End-to-End-Umsetzungsplan fuer Date Planning inklusive finaler Abstimmung, Trip-Date-Migration, horizontalem Kalender und zentral/dezentraler Diskussion.
17. [expense_system_v1_plan_2026-06-10.md](./expense_system_v1_plan_2026-06-10.md)
   - Ueberblick und Sequenz fuer das neue Expense-System V1.
18. [expense_goal_1_domain_ledger_sync_api_2026-06-10.md](./expense_goal_1_domain_ledger_sync_api_2026-06-10.md)
   - Backend-Ziel fuer Trip-Personen, Ledger, Splits, Settlement, Audit und Sync-API.
19. [expense_goal_2_frontend_offline_pwa_2026-06-10.md](./expense_goal_2_frontend_offline_pwa_2026-06-10.md)
   - Frontend-Ziel fuer Expense-App-Island, Quick Capture, Split Editor, Offline Queue und PWA-Verhalten.
20. [expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md](./expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md)
   - Release-Readiness-Ziel fuer Reset, Deploy-Handoff, Smoke Tests, Offline-Walkthrough und operative Freigabe.

## Weitere Dokumente

1. [plangoreminisce-architecture.md](./plangoreminisce-architecture.md)
   - Groesseres Architektur-Dokument.
   - Inhaltlich nuetzlich, aber nicht in allen Teilen auf dem neuesten Stand.
2. Historische Planungsdokumente wurden bewusst entfernt, um widerspruechliche Quellen zu vermeiden.

## Regel

Wenn Dokumente einander widersprechen, gelten zuerst:

1. `stabilization_plan.md`
2. `status_quo.md`
3. der aktuelle Code
