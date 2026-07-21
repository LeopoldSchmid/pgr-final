import { buildSplitPayload, ensureSplitSelection } from "./splits";
import type { ExpenseAppState, ExpenseRecord, ExpenseSnapshot, QuickExpenseDraft, SplitGroup, SplitMode, TripPerson } from "./types";

type RenderActions = {
  onQuickInput: (value: string) => void;
  onQuickAmountInput: (value: string) => void;
  onQuickDescriptionInput: (value: string) => void;
  onSubmitQuickExpense: () => void;
  onRetryLoad: () => void;
  onEditExpense: (expenseId: number) => void;
  onCancelEdit: () => void;
  onEditInput: (expenseId: number, field: "amount" | "description", value: string) => void;
  onSaveEdit: (expenseId: number) => void;
  onVoidExpense: (expenseId: number) => void;
  onDuplicateExpense: (expenseId: number) => void;
  onSplitModeChange: (mode: SplitMode) => void;
  onSplitPersonToggle: (tripPersonId: number) => void;
  onSplitValueChange: (tripPersonId: number, value: string) => void;
  onSelectAllPeople: () => void;
  onRosterDraftChange: (field: "displayName" | "email", value: string) => void;
  onAddTripPerson: () => void;
  onRosterEditChange: (tripPersonId: number, value: string) => void;
  onSaveTripPerson: (tripPersonId: number) => void;
  onSplitGroupDraftChange: (value: string) => void;
  onCreateSplitGroup: () => void;
  onApplySplitGroup: (splitGroupId: number) => void;
  onSplitGroupEditChange: (splitGroupId: number, value: string) => void;
  onSaveSplitGroup: (splitGroupId: number) => void;
};

export function renderExpenseApp(element: HTMLElement, state: ExpenseAppState, actions: RenderActions) {
  const focusState = captureFocusState(element);

  element.innerHTML = template(state);

  element.querySelector<HTMLInputElement>("[data-expense-quick-input]")?.addEventListener("input", (event) => {
    actions.onQuickInput((event.currentTarget as HTMLInputElement).value);
  });

  element.querySelector<HTMLInputElement>("[data-expense-amount-input]")?.addEventListener("input", (event) => {
    actions.onQuickAmountInput((event.currentTarget as HTMLInputElement).value);
  });

  element.querySelector<HTMLInputElement>("[data-expense-description-input]")?.addEventListener("input", (event) => {
    actions.onQuickDescriptionInput((event.currentTarget as HTMLInputElement).value);
  });

  element.querySelector<HTMLFormElement>("[data-expense-quick-form]")?.addEventListener("submit", (event) => {
    event.preventDefault();
    actions.onSubmitQuickExpense();
  });

  element.querySelector<HTMLButtonElement>("[data-expense-retry]")?.addEventListener("click", () => actions.onRetryLoad());

  element.querySelectorAll<HTMLButtonElement>("[data-expense-edit]").forEach((button) => {
    button.addEventListener("click", () => actions.onEditExpense(Number(button.dataset.expenseEdit)));
  });

  element.querySelectorAll<HTMLButtonElement>("[data-expense-edit-cancel]").forEach((button) => {
    button.addEventListener("click", () => actions.onCancelEdit());
  });

  element.querySelectorAll<HTMLInputElement>("[data-expense-edit-input]").forEach((input) => {
    input.addEventListener("input", () => {
      actions.onEditInput(Number(input.dataset.expenseId), input.dataset.expenseField as "amount" | "description", input.value);
    });
  });

  element.querySelectorAll<HTMLButtonElement>("[data-expense-edit-save]").forEach((button) => {
    button.addEventListener("click", () => actions.onSaveEdit(Number(button.dataset.expenseEditSave)));
  });

  element.querySelectorAll<HTMLButtonElement>("[data-expense-void]").forEach((button) => {
    button.addEventListener("click", () => actions.onVoidExpense(Number(button.dataset.expenseVoid)));
  });

  element.querySelectorAll<HTMLButtonElement>("[data-expense-duplicate]").forEach((button) => {
    button.addEventListener("click", () => actions.onDuplicateExpense(Number(button.dataset.expenseDuplicate)));
  });

  element.querySelector<HTMLSelectElement>("[data-expense-split-mode]")?.addEventListener("change", (event) => {
    actions.onSplitModeChange((event.currentTarget as HTMLSelectElement).value as SplitMode);
  });

  element.querySelectorAll<HTMLButtonElement>("[data-expense-split-mode-button]").forEach((button) => {
    button.addEventListener("click", () => actions.onSplitModeChange(button.dataset.expenseSplitModeButton as SplitMode));
  });

  element.querySelectorAll<HTMLInputElement>("[data-expense-split-person]").forEach((input) => {
    input.addEventListener("change", () => actions.onSplitPersonToggle(Number(input.dataset.expenseSplitPerson)));
  });

  element.querySelectorAll<HTMLInputElement>("[data-expense-split-value]").forEach((input) => {
    input.addEventListener("input", () => actions.onSplitValueChange(Number(input.dataset.expenseSplitValue), input.value));
  });

  element.querySelector<HTMLButtonElement>("[data-expense-select-all]")?.addEventListener("click", () => actions.onSelectAllPeople());

  element.querySelectorAll<HTMLInputElement>("[data-expense-roster-draft]").forEach((input) => {
    input.addEventListener("input", () => actions.onRosterDraftChange(input.dataset.expenseRosterDraft as "displayName" | "email", input.value));
  });

  element.querySelector<HTMLFormElement>("[data-expense-roster-form]")?.addEventListener("submit", (event) => {
    event.preventDefault();
    actions.onAddTripPerson();
  });

  element.querySelectorAll<HTMLInputElement>("[data-expense-roster-edit]").forEach((input) => {
    input.addEventListener("input", () => actions.onRosterEditChange(Number(input.dataset.expenseRosterEdit), input.value));
  });

  element.querySelectorAll<HTMLButtonElement>("[data-expense-roster-save]").forEach((button) => {
    button.addEventListener("click", () => actions.onSaveTripPerson(Number(button.dataset.expenseRosterSave)));
  });

  element.querySelector<HTMLInputElement>("[data-expense-group-draft]")?.addEventListener("input", (event) => {
    actions.onSplitGroupDraftChange((event.currentTarget as HTMLInputElement).value);
  });

  element.querySelector<HTMLFormElement>("[data-expense-group-form]")?.addEventListener("submit", (event) => {
    event.preventDefault();
    actions.onCreateSplitGroup();
  });

  element.querySelectorAll<HTMLButtonElement>("[data-expense-group-apply]").forEach((button) => {
    button.addEventListener("click", () => actions.onApplySplitGroup(Number(button.dataset.expenseGroupApply)));
  });

  element.querySelectorAll<HTMLInputElement>("[data-expense-group-edit]").forEach((input) => {
    input.addEventListener("input", () => actions.onSplitGroupEditChange(Number(input.dataset.expenseGroupEdit), input.value));
  });

  element.querySelectorAll<HTMLButtonElement>("[data-expense-group-save]").forEach((button) => {
    button.addEventListener("click", () => actions.onSaveSplitGroup(Number(button.dataset.expenseGroupSave)));
  });

  restoreFocusState(element, focusState);
}

type FocusState = {
  testId: string;
  selectionStart: number | null;
  selectionEnd: number | null;
} | null;

function captureFocusState(element: HTMLElement): FocusState {
  const activeElement = document.activeElement;
  if (!(activeElement instanceof HTMLInputElement) || !element.contains(activeElement)) return null;

  const testId = activeElement.dataset.testid;
  if (!testId) return null;

  return {
    testId,
    selectionStart: activeElement.selectionStart,
    selectionEnd: activeElement.selectionEnd,
  };
}

function restoreFocusState(element: HTMLElement, focusState: FocusState) {
  if (!focusState) return;

  const input = Array.from(element.querySelectorAll<HTMLInputElement>("input[data-testid]")).find((candidate) => candidate.dataset.testid === focusState.testId);
  if (!input || input.disabled) return;

  input.focus();

  if (focusState.selectionStart !== null && focusState.selectionEnd !== null) {
    const selectionStart = Math.min(focusState.selectionStart, input.value.length);
    const selectionEnd = Math.min(focusState.selectionEnd, input.value.length);
    input.setSelectionRange(selectionStart, selectionEnd);
  }
}

function template(state: ExpenseAppState): string {
  const snapshot = state.snapshot;
  const draft = state.quickDraft;

  return `
    <section class="mx-auto flex w-full max-w-6xl flex-col gap-3 px-4 py-4 md:px-6" data-testid="expense-app">
      ${header(snapshot, state)}
      ${panelContent(snapshot, draft, state)}
    </section>
  `;
}

function panelContent(snapshot: ExpenseSnapshot | null, draft: QuickExpenseDraft, state: ExpenseAppState): string {
  if (!snapshot) return quickAdd(draft, state) + loadingState(state);

  if (state.activePanel === "people") return peopleAndGroups(snapshot, state);
  if (state.activePanel === "summary") return dashboard(snapshot) + balancesAndSettlements(snapshot, state) + pendingList(state);
  if (state.activePanel === "activity") return pendingList(state) + activityList(snapshot, state) + expenseList(snapshot.expenses, state);

  return entryPanel(snapshot, draft, state) + pendingList(state);
}

function peopleAndGroups(snapshot: ExpenseSnapshot, state: ExpenseAppState): string {
  const people = snapshot.trip_people.filter((person) => person.status !== "archived");

  return `
    <section class="grid gap-3 md:grid-cols-2" data-testid="expense-roster-groups">
      ${rosterPanel(people, state)}
      ${splitGroupPanel(snapshot.split_groups, state)}
    </section>
  `;
}

function rosterPanel(people: TripPerson[], state: ExpenseAppState): string {
  return `
    <section class="rounded-lg border border-slate-200 bg-white p-3 shadow-sm md:p-4" data-testid="expense-roster">
      <div class="mb-3 flex items-center justify-between gap-3">
        <h2 class="text-sm font-semibold text-slate-900">Travelers</h2>
        <span class="text-xs font-medium text-slate-500">${people.length} active</span>
      </div>
      <form class="grid gap-2 md:grid-cols-[1fr_1fr_auto]" data-expense-roster-form>
        <input data-expense-roster-draft="displayName" data-testid="expense-roster-name" class="min-h-10 rounded-md border border-slate-300 px-3 text-sm" value="${escapeAttribute(state.rosterDraft.displayName)}" placeholder="Name" autocomplete="off">
        <input data-expense-roster-draft="email" data-testid="expense-roster-email" class="min-h-10 rounded-md border border-slate-300 px-3 text-sm" value="${escapeAttribute(state.rosterDraft.email)}" placeholder="Email optional" autocomplete="off">
        <button type="submit" data-testid="expense-roster-add" class="min-h-10 rounded-md bg-slate-950 px-3 text-sm font-semibold text-white">Add</button>
      </form>
      <div class="mt-3 space-y-2">
        ${people.map((person) => rosterRow(person, state)).join("")}
      </div>
    </section>
  `;
}

function rosterRow(person: TripPerson, state: ExpenseAppState): string {
  const draft = state.rosterEditDrafts[person.id]?.displayName ?? person.display_name;
  const disabled = state.syncState === "saving";

  return `
    <div class="grid gap-2 rounded-md border border-slate-200 p-2 md:grid-cols-[1fr_auto] md:items-center" data-testid="expense-roster-person-${person.id}">
      <div class="grid gap-2 md:grid-cols-[1fr_auto] md:items-center">
        <input data-expense-roster-edit="${person.id}" data-testid="expense-roster-display-name-${person.id}" class="min-h-9 rounded-md border border-slate-300 px-2 text-sm" value="${escapeAttribute(draft)}">
        <span class="text-xs font-medium text-slate-500">${escapeHtml(person.status)}</span>
      </div>
      <button type="button" data-expense-roster-save="${person.id}" data-testid="expense-roster-save-${person.id}" class="min-h-9 rounded-md border border-slate-300 px-3 text-sm font-semibold text-slate-700" ${disabled ? "disabled" : ""}>Save</button>
    </div>
  `;
}

function splitGroupPanel(groups: SplitGroup[], state: ExpenseAppState): string {
  const activePeople = state.snapshot?.trip_people.filter((person) => person.status !== "archived") || [];
  const selectedCount = ensureSplitSelection(state.splitDraft, activePeople).selectedTripPersonIds.length;

  return `
    <section class="rounded-lg border border-slate-200 bg-white p-3 shadow-sm md:p-4" data-testid="expense-groups">
      <div class="mb-3 flex items-center justify-between gap-3">
        <h2 class="text-sm font-semibold text-slate-900">Split groups</h2>
        <span class="text-xs font-medium text-slate-500">${selectedCount} selected</span>
      </div>
      <form class="grid gap-2 md:grid-cols-[1fr_auto]" data-expense-group-form>
        <input data-expense-group-draft data-testid="expense-group-name" class="min-h-10 rounded-md border border-slate-300 px-3 text-sm" value="${escapeAttribute(state.splitGroupDraft.name)}" placeholder="Group name" autocomplete="off">
        <button type="submit" data-testid="expense-group-create" class="min-h-10 rounded-md bg-slate-950 px-3 text-sm font-semibold text-white">Save group</button>
      </form>
      <div class="mt-3 space-y-2">
        ${groups.map((group) => splitGroupRow(group, state)).join("") || `<p class="text-sm text-slate-500">No saved groups yet.</p>`}
      </div>
    </section>
  `;
}

function splitGroupRow(group: SplitGroup, state: ExpenseAppState): string {
  const draft = state.splitGroupEditDrafts[group.id]?.name ?? group.name;
  const disabled = state.syncState === "saving";

  return `
    <div class="grid gap-2 rounded-md border border-slate-200 p-2 md:grid-cols-[auto_1fr_auto] md:items-center" data-testid="expense-group-${group.id}">
      <button type="button" data-expense-group-apply="${group.id}" data-testid="expense-group-apply-${group.id}" class="min-h-9 rounded-md border border-blue-200 px-3 text-sm font-semibold text-blue-700">Use</button>
      <input data-expense-group-edit="${group.id}" data-testid="expense-group-rename-${group.id}" class="min-h-9 rounded-md border border-slate-300 px-2 text-sm" value="${escapeAttribute(draft)}">
      <button type="button" data-expense-group-save="${group.id}" data-testid="expense-group-save-${group.id}" class="min-h-9 rounded-md border border-slate-300 px-3 text-sm font-semibold text-slate-700" ${disabled ? "disabled" : ""}>Save</button>
    </div>
  `;
}

function header(snapshot: ExpenseSnapshot | null, state: ExpenseAppState): string {
  const statusClass = state.syncState === "failed" ? "text-red-700 bg-red-50 border-red-200" : "text-slate-700 bg-white border-slate-200";
  const label = state.syncState === "saving" ? "Saving" : state.syncState === "loading" ? "Syncing" : state.syncState === "failed" ? "Needs attention" : "Synced";
  const countLabel = snapshot ? `${snapshot.expenses.length} expenses` : "Loading";

  return `
    <div class="flex items-center justify-between gap-3">
      <div class="text-sm font-medium text-slate-500">${escapeHtml(countLabel)}</div>
      <div class="inline-flex w-fit items-center gap-2 rounded-full border px-3 py-1.5 text-sm font-medium ${statusClass}" data-testid="expense-sync-state">
        <span class="h-2 w-2 rounded-full bg-current"></span>
        ${label}
      </div>
    </div>
    ${state.message ? `<div class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700">${escapeHtml(state.message)} ${state.syncState === "failed" ? `<button class="ml-2 font-semibold text-blue-700" data-expense-retry type="button">Retry</button>` : ""}</div>` : ""}
  `;
}

function entryPanel(snapshot: ExpenseSnapshot, draft: QuickExpenseDraft, state: ExpenseAppState): string {
  return `
    <form class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:p-5" data-expense-quick-form data-testid="expense-quick-form">
      ${quickAddFields(draft, state)}
      ${splitEditor(snapshot, state, draft.amount)}
    </form>
  `;
}

function quickAdd(draft: QuickExpenseDraft, state: ExpenseAppState): string {
  return `
    <form class="rounded-lg border border-slate-200 bg-white p-3 shadow-sm md:p-4" data-expense-quick-form data-testid="expense-quick-form">
      ${quickAddFields(draft, state)}
    </form>
  `;
}

function quickAddFields(draft: QuickExpenseDraft, state: ExpenseAppState): string {
  const canSubmit = draft.amount && draft.description && state.syncState !== "saving";
  const amountValue = amountDraftValue(draft.raw);
  const splitCount = selectedSplitCount(state);
  const payerName = currentPersonName(state);

  return `
      <div class="grid gap-3">
        <div class="grid grid-cols-[minmax(0,1fr)_auto] items-end gap-3">
          <label class="min-w-0">
            <span class="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">Amount</span>
            <span class="flex min-h-14 items-center rounded-2xl border border-slate-300 bg-slate-50 px-4 focus-within:border-blue-600 focus-within:bg-white focus-within:ring-2 focus-within:ring-blue-100">
              <input data-expense-amount-input data-testid="expense-amount-input" class="min-w-0 flex-1 bg-transparent text-3xl font-semibold tabular-nums text-slate-950 outline-none placeholder:text-slate-300" inputmode="decimal" value="${escapeAttribute(amountValue)}" placeholder="0.00" autocomplete="off">
              <span class="ml-2 text-sm font-semibold text-slate-500">${escapeHtml(draft.currency)}</span>
            </span>
          </label>
          <button type="submit" data-testid="expense-quick-submit" class="min-h-12 rounded-full bg-slate-950 px-5 text-sm font-semibold text-white shadow-sm disabled:cursor-not-allowed disabled:bg-slate-300 disabled:text-slate-500" ${canSubmit ? "" : "disabled"}>Save</button>
        </div>
        <label>
          <span class="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">Description</span>
          <input data-expense-description-input data-testid="expense-quick-input" class="min-h-12 w-full rounded-2xl border border-slate-300 bg-white px-4 text-base outline-none transition placeholder:text-slate-400 focus:border-blue-600 focus:ring-2 focus:ring-blue-100" value="${escapeAttribute(draft.description)}" placeholder="Pizza, train tickets, hotel" autocomplete="off">
        </label>
      </div>
      <input type="hidden" data-expense-quick-input value="${escapeAttribute(draft.raw)}">
      <div class="mt-3 flex flex-wrap gap-2 text-sm" data-testid="expense-quick-preview">
        ${contextChip("Paid by", payerName)}
        ${contextChip("Category", draft.category)}
        ${contextChip("Split", splitCount > 0 ? `${splitCount}` : "All")}
      </div>
      ${draft.error ? `<p class="mt-2 text-sm font-medium text-red-700">${escapeHtml(draft.error)}</p>` : ""}
  `;
}

function amountDraftValue(raw: string): string {
  return raw.match(/(?:^|\s)(?:[€$£]|[A-Z]{3})?\s*(\d+(?:[.,]\d{0,2})?)/)?.[1] || "";
}

function selectedSplitCount(state: ExpenseAppState): number {
  const people = state.snapshot?.trip_people.filter((person) => person.status !== "archived") || [];
  return ensureSplitSelection(state.splitDraft, people).selectedTripPersonIds.length;
}

function currentPersonName(state: ExpenseAppState): string {
  const person = state.snapshot?.trip_people.find((candidate) => candidate.user_id === state.currentUserId);
  return person?.display_name || "You";
}

function splitEditor(snapshot: ExpenseSnapshot, state: ExpenseAppState, amount: number | null): string {
  const people = snapshot.trip_people.filter((person) => person.status !== "archived");
  const draft = ensureSplitSelection(state.splitDraft, people);
  const splitResult = amount ? buildSplitPayload(amount, people, draft) : null;

  return `
    <section class="mt-4 grid gap-4 border-t border-slate-100 pt-4" data-testid="expense-split-editor">
      <div class="grid gap-3">
        <div>
          <h2 class="text-sm font-semibold text-slate-950">Split group</h2>
          <div class="mt-2 flex gap-2 overflow-x-auto pb-1">
            <button type="button" data-expense-select-all data-testid="expense-split-all" class="shrink-0 rounded-full border border-slate-300 bg-white px-3 py-1.5 text-sm font-semibold text-slate-700">All</button>
            ${snapshot.split_groups.map((group) => `
              <button type="button" data-expense-group-apply="${group.id}" data-testid="expense-split-group-apply-${group.id}" class="shrink-0 rounded-full border border-blue-200 bg-blue-50 px-3 py-1.5 text-sm font-semibold text-blue-800">${escapeHtml(group.name)}</button>
            `).join("")}
          </div>
        </div>
        <div>
          <h2 class="text-sm font-semibold text-slate-950">Split mode</h2>
          <div class="mt-2 grid grid-cols-4 rounded-2xl bg-slate-100 p-1 text-sm font-semibold">
            ${splitModeButton("equal", "Equal", draft.mode)}
            ${splitModeButton("exact", "Exact", draft.mode)}
            ${splitModeButton("shares", "Shares", draft.mode)}
            ${splitModeButton("percentage", "%", draft.mode)}
          </div>
        </div>
        <select data-expense-split-mode data-testid="expense-split-mode" class="sr-only" tabindex="-1" aria-hidden="true">
          ${splitModeOption("equal", "Equal", draft.mode)}
          ${splitModeOption("exact", "Exact", draft.mode)}
          ${splitModeOption("shares", "Shares", draft.mode)}
          ${splitModeOption("percentage", "%", draft.mode)}
        </select>
      </div>
      <div class="grid gap-2 sm:grid-cols-2 xl:grid-cols-4">
        ${people.map((person) => splitPersonRow(person.id, person.display_name, draft, splitResult?.preview.find((entry) => entry.trip_person_id === person.id)?.amount_owed || "0.00")).join("")}
      </div>
      ${splitResult?.error ? `<p class="mt-3 rounded-md bg-red-50 px-3 py-2 text-sm font-medium text-red-700" data-testid="expense-split-error">${escapeHtml(splitResult.error)}</p>` : ""}
    </section>
  `;
}

function splitPersonRow(personId: number, displayName: string, draft: ExpenseAppState["splitDraft"], previewAmount: string): string {
  const checked = draft.selectedTripPersonIds.includes(personId);
  const requiresValue = draft.mode !== "equal";
  const placeholder = draft.mode === "percentage" ? "50" : draft.mode === "shares" ? "1" : "0.00";

  return `
    <label class="grid gap-2 rounded-lg border ${checked ? "border-blue-300 bg-blue-50" : "border-slate-200 bg-white"} p-2.5 text-sm">
      <span class="flex min-w-0 items-center gap-2">
        <input type="checkbox" data-expense-split-person="${personId}" data-testid="expense-split-person-${personId}" ${checked ? "checked" : ""}>
        <span class="min-w-0 flex-1 truncate font-medium text-slate-900">${escapeHtml(displayName)}</span>
        <span class="shrink-0 font-semibold text-slate-700" data-testid="expense-split-preview-${personId}">${checked ? escapeHtml(previewAmount) : "0.00"}</span>
      </span>
      ${requiresValue ? `<input data-expense-split-value="${personId}" data-testid="expense-split-value-${personId}" class="min-h-9 min-w-0 rounded-md border border-slate-300 px-2 text-sm" inputmode="decimal" value="${escapeAttribute(draft.values[personId] || "")}" placeholder="${placeholder}" ${checked ? "" : "disabled"}>` : ""}
    </label>
  `;
}

function splitModeOption(value: SplitMode, label: string, current: SplitMode): string {
  return `<option value="${value}" ${value === current ? "selected" : ""}>${label}</option>`;
}

function splitModeButton(value: SplitMode, label: string, current: SplitMode): string {
  const selected = value === current;
  return `<button type="button" data-expense-split-mode-button="${value}" class="min-h-9 rounded-xl px-2 text-center transition ${selected ? "bg-white text-slate-950 shadow-sm" : "text-slate-600"}">${label}</button>`;
}

function dashboard(snapshot: ExpenseSnapshot): string {
  const total = snapshot.expenses.reduce((sum, expense) => sum + Number(expense.amount), 0);
  const activeCount = snapshot.expenses.filter((expense) => expense.status === "active").length;

  return `
    <div class="grid gap-3 md:grid-cols-4">
      ${metric("Total spend", money(total))}
      ${metric("Expenses", String(snapshot.expenses.length))}
      ${metric("Active", String(activeCount))}
      ${metric("Settlements", String(snapshot.settlement_suggestions.length))}
    </div>
  `;
}

function balancesAndSettlements(snapshot: ExpenseSnapshot, state: ExpenseAppState): string {
  const currentPerson = snapshot.trip_people.find((person) => person.user_id === state.currentUserId);
  const currentBalance = currentPerson ? snapshot.balances.find((balance) => balance.trip_person_id === currentPerson.id) : null;

  return `
    <section class="grid gap-3 md:grid-cols-2" data-testid="expense-ledger-summary">
      <div class="rounded-lg border border-slate-200 bg-white p-3 shadow-sm md:p-4" data-testid="expense-balances">
        <div class="mb-3 flex items-center justify-between gap-3">
          <h2 class="text-sm font-semibold text-slate-900">Balances</h2>
          <span class="text-xs font-medium text-slate-500">${currentBalance ? `You: ${escapeHtml(currentBalance.amount)} EUR` : "Trip"}</span>
        </div>
        <div class="space-y-2">
          ${snapshot.balances.map((balance) => `
            <div class="flex items-center justify-between gap-3 rounded-md bg-slate-50 px-3 py-2 text-sm">
              <span class="min-w-0 truncate font-medium text-slate-800">${escapeHtml(personName(snapshot, balance.trip_person_id))}</span>
              <span class="shrink-0 font-semibold ${Number(balance.amount) < 0 ? "text-red-700" : "text-emerald-700"}">${escapeHtml(balance.amount)} EUR</span>
            </div>
          `).join("") || `<p class="text-sm text-slate-500">No balances yet.</p>`}
        </div>
      </div>
      <div class="rounded-lg border border-slate-200 bg-white p-3 shadow-sm md:p-4" data-testid="expense-settlements">
        <div class="mb-3 flex items-center justify-between gap-3">
          <h2 class="text-sm font-semibold text-slate-900">Settle up</h2>
          <span class="text-xs font-medium text-slate-500">${snapshot.settlement_suggestions.length} suggestions</span>
        </div>
        <div class="space-y-2">
          ${snapshot.settlement_suggestions.map((settlement) => `
            <div class="rounded-md bg-slate-50 px-3 py-2 text-sm">
              <p class="font-medium text-slate-900">${escapeHtml(personName(snapshot, settlement.from_trip_person_id))} pays ${escapeHtml(personName(snapshot, settlement.to_trip_person_id))}</p>
              <p class="text-xs font-semibold text-slate-600">${escapeHtml(settlement.amount)} ${escapeHtml(settlement.currency)}</p>
            </div>
          `).join("") || `<p class="text-sm text-slate-500">Nothing to settle yet.</p>`}
        </div>
      </div>
    </section>
  `;
}

function activityList(snapshot: ExpenseSnapshot, state: ExpenseAppState): string {
  const recentExpenses = snapshot.expenses.slice(0, 5).map((expense) => ({
    title: expense.status === "voided" ? `Voided: ${expense.description}` : `${expense.lock_version > 0 ? "Updated" : "Added"}: ${expense.description}`,
    detail: `${expense.amount} ${expense.currency} · ${expense.expense_date} · ${expense.splits.length} people`,
  }));
  const pending = state.pendingMutations.slice(0, 5).map((mutation) => ({
    title: `Pending ${mutation.mutation_type.replace("expense_", "")}`,
    detail: mutation.last_error || "Waiting to sync.",
  }));
  const events = [...pending, ...recentExpenses].slice(0, 6);

  if (events.length === 0) return "";

  return `
    <section class="rounded-lg border border-slate-200 bg-white p-3 shadow-sm md:p-4" data-testid="expense-activity">
      <div class="mb-3 flex items-center justify-between gap-3">
        <h2 class="text-sm font-semibold text-slate-900">Activity</h2>
        <span class="text-xs font-medium text-slate-500">Recent changes</span>
      </div>
      <div class="space-y-2">
        ${events.map((event) => `
          <article class="rounded-md bg-slate-50 px-3 py-2 text-sm">
            <p class="font-medium text-slate-900">${escapeHtml(event.title)}</p>
            <p class="text-xs text-slate-500">${escapeHtml(event.detail)}</p>
          </article>
        `).join("")}
      </div>
    </section>
  `;
}

function expenseList(expenses: ExpenseRecord[], state: ExpenseAppState): string {
  if (expenses.length === 0) {
    return `<div class="rounded-lg border border-dashed border-slate-300 bg-white p-8 text-center text-slate-600">No expenses yet.</div>`;
  }

  return `
    <div class="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm" data-testid="expense-list">
      ${expenses.map((expense) => expenseRow(expense, state)).join("")}
    </div>
  `;
}

function expenseRow(expense: ExpenseRecord, state: ExpenseAppState): string {
  const draft = state.editDrafts[expense.id] || { amount: Number(expense.amount).toFixed(2), description: expense.description };
  const isEditing = state.editingExpenseId === expense.id;
  const disabled = state.syncState === "saving";

  if (isEditing) {
    return `
      <article class="border-b border-slate-100 px-4 py-3 last:border-b-0" data-testid="expense-row-${expense.id}">
        <div class="grid gap-2 md:grid-cols-[1fr_8rem_auto] md:items-center">
          <input data-expense-edit-input data-expense-id="${expense.id}" data-expense-field="description" data-testid="expense-edit-description-${expense.id}" class="min-h-10 rounded-md border border-slate-300 px-3 text-sm" value="${escapeAttribute(draft.description)}">
          <input data-expense-edit-input data-expense-id="${expense.id}" data-expense-field="amount" data-testid="expense-edit-amount-${expense.id}" class="min-h-10 rounded-md border border-slate-300 px-3 text-sm" inputmode="decimal" value="${escapeAttribute(draft.amount)}">
          <div class="flex gap-2">
            <button type="button" data-expense-edit-save="${expense.id}" data-testid="expense-edit-save-${expense.id}" class="min-h-10 rounded-md bg-slate-950 px-3 text-sm font-semibold text-white" ${disabled ? "disabled" : ""}>Save</button>
            <button type="button" data-expense-edit-cancel class="min-h-10 rounded-md border border-slate-300 px-3 text-sm font-semibold text-slate-700">Cancel</button>
          </div>
        </div>
      </article>
    `;
  }

  return `
    <article class="flex flex-col gap-3 border-b border-slate-100 px-4 py-3 last:border-b-0 md:flex-row md:items-center md:justify-between" data-testid="expense-row-${expense.id}">
      <div class="min-w-0">
        <h2 class="truncate text-sm font-semibold text-slate-950">${escapeHtml(expense.description)}</h2>
        <p class="text-xs text-slate-500">${escapeHtml(expense.category)} · ${escapeHtml(expense.expense_date)} · ${expense.splits.length} people · rev ${expense.lock_version}</p>
      </div>
      <div class="flex shrink-0 items-center justify-between gap-3 md:justify-end">
        <div class="text-right">
          <p class="font-semibold text-slate-950">${escapeHtml(expense.amount)} ${escapeHtml(expense.currency)}</p>
          <p class="text-xs text-slate-500">${escapeHtml(expense.status)}</p>
        </div>
        <div class="flex gap-2">
          <button type="button" data-expense-edit="${expense.id}" data-testid="expense-edit-${expense.id}" class="min-h-9 rounded-md border border-slate-300 px-3 text-sm font-semibold text-slate-700" ${disabled || expense.status === "voided" ? "disabled" : ""}>Edit</button>
          <button type="button" data-expense-duplicate="${expense.id}" data-testid="expense-duplicate-${expense.id}" class="min-h-9 rounded-md border border-blue-200 px-3 text-sm font-semibold text-blue-700">Copy</button>
          <button type="button" data-expense-void="${expense.id}" data-testid="expense-void-${expense.id}" class="min-h-9 rounded-md border border-red-200 px-3 text-sm font-semibold text-red-700" ${disabled || expense.status === "voided" ? "disabled" : ""}>Void</button>
        </div>
      </div>
    </article>
  `;
}

function pendingList(state: ExpenseAppState): string {
  if (state.pendingMutations.length === 0) return "";

  return `
    <div class="rounded-lg border border-amber-200 bg-amber-50 p-4" data-testid="expense-pending-list">
      <div class="mb-2 flex items-center justify-between gap-3">
        <h2 class="text-sm font-semibold text-amber-950">Pending sync</h2>
        <span class="text-xs font-medium text-amber-800">${state.pendingMutations.length} queued</span>
      </div>
      <div class="space-y-2">
        ${state.pendingMutations.map((mutation) => `
          <article class="rounded-md bg-white px-3 py-2 text-sm shadow-sm" data-testid="expense-pending-item" data-testid-kind="${mutation.mutation_type}">
            <div class="flex items-center justify-between gap-3">
              <span class="min-w-0 truncate font-semibold text-slate-950">${escapeHtml(pendingTitle(mutation))}</span>
              <span class="shrink-0 rounded-full px-2 py-1 text-xs font-semibold ${pendingStatusClass(mutation.sync_status)}">${escapeHtml(mutation.sync_status)}</span>
            </div>
            <p class="mt-1 text-xs text-amber-800">${escapeHtml(mutation.last_error || "Waiting to sync.")}</p>
          </article>
        `).join("")}
      </div>
    </div>
  `;
}

function pendingTitle(mutation: ExpenseAppState["pendingMutations"][number]): string {
  if (mutation.mutation_type === "expense_create") {
    return `${mutation.payload.expense.description} · ${mutation.payload.expense.amount} ${mutation.payload.expense.currency}`;
  }

  if (mutation.mutation_type === "expense_update") {
    return `Edit expense #${mutation.payload.expense_id} · ${mutation.payload.expense.amount || ""} ${mutation.payload.expense.currency || ""}`.trim();
  }

  return `Void expense #${mutation.payload.expense_id}`;
}

function pendingStatusClass(status: ExpenseAppState["pendingMutations"][number]["sync_status"]): string {
  if (status === "conflict") return "bg-red-100 text-red-800";
  if (status === "rejected") return "bg-slate-200 text-slate-800";
  if (status === "failed") return "bg-orange-100 text-orange-800";
  return "bg-amber-100 text-amber-800";
}

function loadingState(state: ExpenseAppState): string {
  if (state.syncState === "failed") return "";
  return `<div class="rounded-lg border border-slate-200 bg-white p-8 text-center text-slate-600">Loading expenses...</div>`;
}

function metric(label: string, value: string): string {
  return `
    <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <p class="text-sm text-slate-500">${escapeHtml(label)}</p>
      <p class="mt-1 text-2xl font-semibold text-slate-950">${escapeHtml(value)}</p>
    </div>
  `;
}

function previewPill(label: string, value: string): string {
  return `
    <div class="rounded-md bg-slate-50 px-3 py-2">
      <p class="text-xs font-medium text-slate-500">${escapeHtml(label)}</p>
      <p class="truncate font-semibold text-slate-900">${escapeHtml(value)}</p>
    </div>
  `;
}

function contextChip(label: string, value: string): string {
  return `
    <span class="inline-flex max-w-full items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5 text-sm text-slate-600">
      <span>${escapeHtml(label)}</span>
      <strong class="truncate font-semibold text-slate-950">${escapeHtml(value)}</strong>
    </span>
  `;
}

function money(value: number): string {
  return `${value.toFixed(2)} EUR`;
}

function personName(snapshot: ExpenseSnapshot, tripPersonId: number): string {
  return snapshot.trip_people.find((person) => person.id === tripPersonId)?.display_name || "Unknown";
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => {
    const escapes: Record<string, string> = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
    return escapes[character];
  });
}

function escapeAttribute(value: string): string {
  return escapeHtml(value).replace(/`/g, "&#96;");
}
