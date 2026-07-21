import { Controller } from "@hotwired/stimulus";
import { createSplitGroup, createTripPerson, ExpenseSyncError, fetchSnapshot, submitExpenseMutation, updateSplitGroup, updateTripPerson } from "../expenses/api";
import { enqueuePendingMutation, loadPendingMutations, loadSnapshot, removePendingMutation, saveSnapshot, updatePendingMutationError } from "../expenses/db";
import { parseQuickExpense } from "../expenses/parser";
import { buildSplitPayload, ensureSplitSelection } from "../expenses/splits";
import { createInitialState, reducer, selectCurrentTripPerson } from "../expenses/store";
import { renderExpenseApp } from "../expenses/render";
import type { ClientExpenseMutation, ExpenseAppState, ExpensePanel, ExpenseRecord, PendingExpenseMutation } from "../expenses/types";

export default class extends Controller<HTMLElement> {
  static values = {
    snapshotUrl: String,
    mutationUrl: String,
    tripPeopleUrl: String,
    splitGroupsUrl: String,
    currentUserId: Number,
    initialPanel: String,
  };

  declare readonly snapshotUrlValue: string;
  declare readonly mutationUrlValue: string;
  declare readonly tripPeopleUrlValue: string;
  declare readonly splitGroupsUrlValue: string;
  declare readonly currentUserIdValue: number;
  declare readonly initialPanelValue: string;

  private state: ExpenseAppState = createInitialState();

  connect() {
    this.state = reducer(this.state, { type: "panelSelected", panel: this.initialPanel() });
    window.addEventListener("online", this.syncPendingMutations);
    this.load();
    this.render();
  }

  disconnect() {
    window.removeEventListener("online", this.syncPendingMutations);
  }

  private async load() {
    this.state = reducer(this.state, { type: "loadStarted" });
    await this.refreshPendingMutationsSafely();
    this.render();

    try {
      const snapshot = await fetchSnapshot(this.snapshotUrlValue);
      await saveSnapshot(snapshot);
      this.state = reducer(this.state, { type: "loadSucceeded", snapshot, currentUserId: this.currentUserIdValue });
    } catch (error) {
      const cachedSnapshot = await loadSnapshot(this.tripIdFromSnapshotUrl());
      if (cachedSnapshot) {
        this.state = reducer(this.state, { type: "loadSucceeded", snapshot: cachedSnapshot, currentUserId: this.currentUserIdValue });
        this.state = { ...this.state, message: "Using the last cached expense snapshot." };
      } else {
        this.state = reducer(this.state, {
          type: "loadFailed",
          message: error instanceof Error ? error.message : "Could not load expenses.",
        });
      }
    }

    this.render();
    await this.syncPendingMutations();
  }

  private render() {
    renderExpenseApp(this.element, this.state, {
      onQuickInput: (value) => {
        this.state = reducer(this.state, { type: "quickInputChanged", value });
        this.render();
      },
      onQuickAmountInput: (value) => {
        this.state = reducer(this.state, { type: "quickInputChanged", value: this.quickRaw(value, this.state.quickDraft.description) });
        this.render();
      },
      onQuickDescriptionInput: (value) => {
        this.state = reducer(this.state, { type: "quickInputChanged", value: this.quickRaw(this.quickAmountValue(), value) });
        this.render();
      },
      onSubmitQuickExpense: () => this.submitQuickExpense(),
      onRetryLoad: () => this.syncPendingMutations().then(() => this.load()),
      onEditExpense: (expenseId) => this.startEdit(expenseId),
      onCancelEdit: () => {
        this.state = reducer(this.state, { type: "editCancelled" });
        this.render();
      },
      onEditInput: (expenseId, field, value) => {
        this.state = reducer(this.state, { type: "editChanged", expenseId, field, value });
        this.render();
      },
      onSaveEdit: (expenseId) => this.saveEdit(expenseId),
      onVoidExpense: (expenseId) => this.voidExpense(expenseId),
      onDuplicateExpense: (expenseId) => this.duplicateExpense(expenseId),
      onSplitModeChange: (mode) => {
        this.state = reducer(this.state, { type: "splitModeChanged", mode });
        this.render();
      },
      onSplitPersonToggle: (tripPersonId) => {
        this.state = reducer(this.state, { type: "splitPersonToggled", tripPersonId });
        this.render();
      },
      onSplitValueChange: (tripPersonId, value) => {
        this.state = reducer(this.state, { type: "splitValueChanged", tripPersonId, value });
        this.render();
      },
      onSelectAllPeople: () => {
        const tripPersonIds = this.state.snapshot?.trip_people.filter((person) => person.status !== "archived").map((person) => person.id) || [];
        this.state = reducer(this.state, { type: "splitPeopleSelected", tripPersonIds });
        this.render();
      },
      onRosterDraftChange: (field, value) => {
        this.state = reducer(this.state, { type: "rosterDraftChanged", field, value });
        this.render();
      },
      onAddTripPerson: () => this.addTripPerson(),
      onRosterEditChange: (tripPersonId, value) => {
        this.state = reducer(this.state, { type: "rosterEditChanged", tripPersonId, value });
        this.render();
      },
      onSaveTripPerson: (tripPersonId) => this.saveTripPerson(tripPersonId),
      onSplitGroupDraftChange: (value) => {
        this.state = reducer(this.state, { type: "splitGroupDraftChanged", value });
        this.render();
      },
      onCreateSplitGroup: () => this.createSplitGroupFromSelection(),
      onApplySplitGroup: (splitGroupId) => this.applySplitGroup(splitGroupId),
      onSplitGroupEditChange: (splitGroupId, value) => {
        this.state = reducer(this.state, { type: "splitGroupEditChanged", splitGroupId, value });
        this.render();
      },
      onSaveSplitGroup: (splitGroupId) => this.saveSplitGroup(splitGroupId),
    });
  }

  private async submitQuickExpense() {
    const draft = this.state.quickDraft;
    const snapshot = this.state.snapshot;

    if (!snapshot || !draft.amount || !draft.description) {
      this.state = reducer(this.state, { type: "quickSubmitRejected", message: "Enter an amount and description." });
      this.render();
      return;
    }

    const payer = selectCurrentTripPerson(snapshot, this.currentUserIdValue);
    if (!payer) {
      this.state = reducer(this.state, { type: "quickSubmitRejected", message: "No trip person is linked to your user yet." });
      this.render();
      return;
    }

    const splitPeople = snapshot.trip_people.filter((person) => person.status !== "archived");
    const splitResult = buildSplitPayload(draft.amount, splitPeople, ensureSplitSelection(this.state.splitDraft, splitPeople));
    if (splitResult.error) {
      this.state = reducer(this.state, { type: "quickSubmitRejected", message: splitResult.error });
      this.render();
      return;
    }

    const clientUuid = crypto.randomUUID();
    const mutation: ClientExpenseMutation = {
      client_uuid: clientUuid,
      mutation_type: "expense_create",
      payload: {
        expense: {
          client_uuid: clientUuid,
          amount: draft.amount.toFixed(2),
          description: draft.description,
          category: draft.category,
          currency: draft.currency,
          expense_date: new Date().toISOString().slice(0, 10),
          payer_trip_person_id: payer.id,
        },
        splits: splitResult.splits,
      },
    };

    this.state = reducer(this.state, { type: "quickSubmitStarted", clientUuid });
    this.render();

    try {
      await submitExpenseMutation(this.mutationUrlValue, mutation);

      this.state = reducer(this.state, { type: "quickSubmitSucceeded" });
      this.render();
      await this.load();
    } catch (error) {
      await enqueuePendingMutation({
        ...mutation,
        queued_at: new Date().toISOString(),
        last_error: error instanceof Error ? error.message : "Waiting for connection.",
        sync_status: "pending",
        conflict: null,
      });
      await this.refreshPendingMutations();
      this.state = reducer(this.state, { type: "quickSubmitSucceeded" });
      this.state = { ...this.state, message: "Expense saved locally and will sync when the connection works." };
      this.render();
    }
  }

  private quickAmountValue() {
    return this.state.quickDraft.amount ? this.state.quickDraft.amount.toFixed(2) : "";
  }

  private quickRaw(amount: string, description: string) {
    return [amount.trim(), description.trim()].filter(Boolean).join(" ");
  }

  private initialPanel(): ExpensePanel {
    const panel = this.initialPanelValue;
    return panel === "people" || panel === "summary" || panel === "activity" ? panel : "entry";
  }

  private startEdit(expenseId: number) {
    const expense = this.findExpense(expenseId);
    if (!expense) return;

    this.state = reducer(this.state, {
      type: "editStarted",
      expenseId,
      amount: Number(expense.amount).toFixed(2),
      description: expense.description,
    });
    this.render();
  }

  private async saveEdit(expenseId: number) {
    const expense = this.findExpense(expenseId);
    const draft = this.state.editDrafts[expenseId];
    if (!expense || !draft) return;

    const amount = Number.parseFloat(draft.amount.replace(",", "."));
    if (!Number.isFinite(amount) || amount <= 0 || draft.description.trim().length === 0) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: "Enter a valid amount and description." });
      this.render();
      return;
    }

    const splitPeople = this.editSplitPeople(expense);
    const splitResult = buildSplitPayload(amount, splitPeople, ensureSplitSelection(this.state.splitDraft, splitPeople));
    if (splitResult.error) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: splitResult.error });
      this.render();
      return;
    }

    const clientUuid = crypto.randomUUID();
    const mutation: ClientExpenseMutation = {
      client_uuid: clientUuid,
      mutation_type: "expense_update",
      payload: {
        expense_id: expense.id,
        base_revision: expense.lock_version,
        expense: {
          amount: amount.toFixed(2),
          description: draft.description.trim(),
          category: expense.category,
          currency: expense.currency,
          expense_date: expense.expense_date,
          payer_trip_person_id: expense.payer_trip_person_id,
        },
        splits: splitResult.splits,
      },
    };

    await this.submitOrQueueMutation(mutation, "Expense updated.", "Expense edit saved locally and will sync when the connection works.");
  }

  private async voidExpense(expenseId: number) {
    const expense = this.findExpense(expenseId);
    if (!expense) return;

    const clientUuid = crypto.randomUUID();
    const mutation: ClientExpenseMutation = {
      client_uuid: clientUuid,
      mutation_type: "expense_void",
      payload: {
        expense_id: expense.id,
        base_revision: expense.lock_version,
      },
    };

    await this.submitOrQueueMutation(mutation, "Expense voided.", "Expense void saved locally and will sync when the connection works.");
  }

  private duplicateExpense(expenseId: number) {
    const expense = this.findExpense(expenseId);
    if (!expense) return;

    this.state = reducer(this.state, { type: "quickDraftPrefilled", value: `${Number(expense.amount).toFixed(2)} ${expense.description}` });
    this.render();
  }

  private async submitOrQueueMutation(mutation: ClientExpenseMutation, successMessage: string, queuedMessage: string) {
    this.state = reducer(this.state, { type: "expenseMutationStarted", clientUuid: mutation.client_uuid });
    this.render();

    try {
      await submitExpenseMutation(this.mutationUrlValue, mutation);
      this.state = reducer(this.state, { type: "expenseMutationSucceeded", message: successMessage });
      this.render();
      await this.load();
    } catch (error) {
      if (error instanceof ExpenseSyncError && (error.body?.status === "conflict" || error.body?.status === "rejected")) {
        await enqueuePendingMutation(this.pendingFromError(mutation, error));
        await this.refreshPendingMutations();
        this.state = reducer(this.state, { type: "expenseMutationFailed", message: error.body?.status === "conflict" ? "Sync conflict needs review." : "Sync change was rejected." });
        this.render();
        return;
      }

      await enqueuePendingMutation({
        ...mutation,
        queued_at: new Date().toISOString(),
        last_error: error instanceof Error ? error.message : "Waiting for connection.",
        sync_status: "pending",
        conflict: null,
      });
      await this.refreshPendingMutations();
      this.state = reducer(this.state, { type: "expenseMutationQueued", message: queuedMessage });
      this.render();
    }
  }

  private async addTripPerson() {
    const displayName = this.state.rosterDraft.displayName.trim();
    const email = this.state.rosterDraft.email.trim();
    if (!displayName) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: "Enter a name for the traveler." });
      this.render();
      return;
    }

    this.state = reducer(this.state, { type: "expenseMutationStarted", clientUuid: crypto.randomUUID() });
    this.render();

    try {
      const person = await createTripPerson(this.tripPeopleUrlValue, {
        display_name: displayName,
        email: email || null,
        status: email ? "invited" : "placeholder",
      });
      const existingPeople = this.state.snapshot?.trip_people.filter((tripPerson) => tripPerson.status !== "archived") || [];
      const selectedIds = ensureSplitSelection(this.state.splitDraft, existingPeople).selectedTripPersonIds;
      this.state = reducer(this.state, { type: "rosterDraftReset" });
      this.state = reducer(this.state, { type: "splitPeopleSelected", tripPersonIds: [...selectedIds, person.id] });
      this.state = reducer(this.state, { type: "expenseMutationSucceeded", message: "Traveler added." });
      this.render();
      await this.load();
    } catch (error) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: error instanceof Error ? error.message : "Could not add traveler." });
      this.render();
    }
  }

  private async saveTripPerson(tripPersonId: number) {
    const displayName = this.state.rosterEditDrafts[tripPersonId]?.displayName.trim();
    if (!displayName) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: "Traveler name cannot be blank." });
      this.render();
      return;
    }

    this.state = reducer(this.state, { type: "expenseMutationStarted", clientUuid: crypto.randomUUID() });
    this.render();

    try {
      const person = await updateTripPerson(this.tripPeopleUrlValue, tripPersonId, { display_name: displayName });
      if (this.state.snapshot) {
        this.state = {
          ...this.state,
          snapshot: {
            ...this.state.snapshot,
            trip_people: this.state.snapshot.trip_people.map((tripPerson) => tripPerson.id === person.id ? person : tripPerson),
          },
        };
      }
      this.state = reducer(this.state, { type: "expenseMutationSucceeded", message: "Traveler updated." });
      this.render();
      await this.load();
    } catch (error) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: error instanceof Error ? error.message : "Could not update traveler." });
      this.render();
    }
  }

  private async createSplitGroupFromSelection() {
    const name = this.state.splitGroupDraft.name.trim();
    const people = this.state.snapshot?.trip_people.filter((tripPerson) => tripPerson.status !== "archived") || [];
    const tripPersonIds = ensureSplitSelection(this.state.splitDraft, people).selectedTripPersonIds;
    if (!name || tripPersonIds.length === 0) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: "Name the group and select at least one traveler." });
      this.render();
      return;
    }

    this.state = reducer(this.state, { type: "expenseMutationStarted", clientUuid: crypto.randomUUID() });
    this.render();

    try {
      await createSplitGroup(this.splitGroupsUrlValue, { name, kind: "custom", trip_person_ids: tripPersonIds });
      this.state = reducer(this.state, { type: "splitGroupDraftReset" });
      this.state = reducer(this.state, { type: "expenseMutationSucceeded", message: "Split group saved." });
      this.render();
      await this.load();
    } catch (error) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: error instanceof Error ? error.message : "Could not save split group." });
      this.render();
    }
  }

  private applySplitGroup(splitGroupId: number) {
    const group = this.state.snapshot?.split_groups.find((splitGroup) => splitGroup.id === splitGroupId);
    if (!group) return;

    this.state = reducer(this.state, { type: "splitPeopleSelected", tripPersonIds: group.trip_person_ids });
    this.render();
  }

  private async saveSplitGroup(splitGroupId: number) {
    const group = this.state.snapshot?.split_groups.find((splitGroup) => splitGroup.id === splitGroupId);
    const name = this.state.splitGroupEditDrafts[splitGroupId]?.name.trim();
    if (!group || !name) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: "Split group name cannot be blank." });
      this.render();
      return;
    }

    this.state = reducer(this.state, { type: "expenseMutationStarted", clientUuid: crypto.randomUUID() });
    this.render();

    try {
      const splitGroup = await updateSplitGroup(this.splitGroupsUrlValue, splitGroupId, { name, trip_person_ids: group.trip_person_ids });
      if (this.state.snapshot) {
        this.state = {
          ...this.state,
          snapshot: {
            ...this.state.snapshot,
            split_groups: this.state.snapshot.split_groups.map((groupEntry) => groupEntry.id === splitGroup.id ? splitGroup : groupEntry),
          },
        };
      }
      this.state = reducer(this.state, { type: "expenseMutationSucceeded", message: "Split group updated." });
      this.render();
      await this.load();
    } catch (error) {
      this.state = reducer(this.state, { type: "expenseMutationFailed", message: error instanceof Error ? error.message : "Could not update split group." });
      this.render();
    }
  }

  private syncPendingMutations = async () => {
    const pending = await loadPendingMutations();
    if (pending.length === 0) {
      this.state = reducer(this.state, { type: "pendingLoaded", pendingMutations: [] });
      this.render();
      return;
    }

    for (const mutation of pending) {
      if (mutation.sync_status === "conflict" || mutation.sync_status === "rejected") continue;

      try {
        await submitExpenseMutation(this.mutationUrlValue, mutation);
        await removePendingMutation(mutation.client_uuid);
      } catch (error) {
        if (error instanceof ExpenseSyncError && error.body?.status === "conflict") {
          await updatePendingMutationError(mutation.client_uuid, "Sync conflict needs review.", "conflict", error.body);
        } else if (error instanceof ExpenseSyncError && error.body?.status === "rejected") {
          await updatePendingMutationError(mutation.client_uuid, error.message, "rejected", error.body);
        } else {
          await updatePendingMutationError(
            mutation.client_uuid,
            error instanceof Error ? error.message : "Still waiting to sync.",
            "failed",
          );
        }
      }
    }

    await this.refreshPendingMutations();
    this.render();
  };

  private async refreshPendingMutations() {
    const pendingMutations = await loadPendingMutations();
    this.state = reducer(this.state, { type: "pendingLoaded", pendingMutations });
  }

  private async refreshPendingMutationsSafely() {
    try {
      await this.refreshPendingMutations();
    } catch (error) {
      console.error("Could not load pending expense mutations", error);
    }
  }

  private tripIdFromSnapshotUrl() {
    const match = this.snapshotUrlValue.match(/\/api\/trips\/(\d+)\/expense_snapshot/);
    return match?.[1] || "current";
  }

  private findExpense(expenseId: number) {
    return this.state.snapshot?.expenses.find((expense) => expense.id === expenseId) || null;
  }

  private editSplitPeople(expense: ExpenseRecord) {
    const snapshot = this.state.snapshot;
    if (!snapshot) return [];

    const splitIds = expense.splits.map((split) => split.trip_person_id);
    const people = snapshot.trip_people.filter((person) => splitIds.includes(person.id));
    return people.length > 0 ? people : snapshot.trip_people.filter((person) => person.status !== "archived");
  }

  private pendingFromError(mutation: ClientExpenseMutation, error: ExpenseSyncError): PendingExpenseMutation {
    return {
      ...mutation,
      queued_at: new Date().toISOString(),
      last_error: error.message,
      sync_status: error.body?.status === "conflict" ? "conflict" : "rejected",
      conflict: error.body,
    };
  }
}

export { parseQuickExpense };
