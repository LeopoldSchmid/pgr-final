import { parseQuickExpense } from "./parser";
import { createDefaultSplitDraft } from "./splits";
import type { ExpenseAppState, ExpensePanel, ExpenseSnapshot, PendingExpenseMutation, SplitMode, TripPerson } from "./types";

type Action =
  | { type: "loadStarted" }
  | { type: "loadSucceeded"; snapshot: ExpenseSnapshot; currentUserId: number }
  | { type: "pendingLoaded"; pendingMutations: PendingExpenseMutation[] }
  | { type: "loadFailed"; message: string }
  | { type: "panelSelected"; panel: ExpensePanel }
  | { type: "quickInputChanged"; value: string }
  | { type: "quickDraftPrefilled"; value: string }
  | { type: "quickSubmitStarted"; clientUuid: string }
  | { type: "quickSubmitSucceeded" }
  | { type: "quickSubmitRejected"; message: string }
  | { type: "quickSubmitFailed"; message: string }
  | { type: "editStarted"; expenseId: number; amount: string; description: string }
  | { type: "editCancelled" }
  | { type: "editChanged"; expenseId: number; field: "amount" | "description"; value: string }
  | { type: "expenseMutationStarted"; clientUuid: string }
  | { type: "expenseMutationSucceeded"; message: string }
  | { type: "expenseMutationQueued"; message: string }
  | { type: "expenseMutationFailed"; message: string }
  | { type: "splitModeChanged"; mode: SplitMode }
  | { type: "splitPersonToggled"; tripPersonId: number }
  | { type: "splitValueChanged"; tripPersonId: number; value: string }
  | { type: "splitPeopleSelected"; tripPersonIds: number[] }
  | { type: "rosterDraftChanged"; field: "displayName" | "email"; value: string }
  | { type: "rosterDraftReset" }
  | { type: "rosterEditChanged"; tripPersonId: number; value: string }
  | { type: "splitGroupDraftChanged"; value: string }
  | { type: "splitGroupDraftReset" }
  | { type: "splitGroupEditChanged"; splitGroupId: number; value: string };

export function createInitialState(): ExpenseAppState {
  return {
    snapshot: null,
    currentUserId: null,
    activePanel: "entry",
    syncState: "idle",
    message: null,
    quickDraft: parseQuickExpense(""),
    pendingClientUuid: null,
    pendingMutations: [],
    editingExpenseId: null,
    editDrafts: {},
    splitDraft: createDefaultSplitDraft(),
    rosterDraft: { displayName: "", email: "" },
    rosterEditDrafts: {},
    splitGroupDraft: { name: "" },
    splitGroupEditDrafts: {},
  };
}

export function reducer(state: ExpenseAppState, action: Action): ExpenseAppState {
  switch (action.type) {
    case "loadStarted":
      return { ...state, syncState: "loading", message: "Loading latest expenses..." };
    case "loadSucceeded":
      return {
        ...state,
        snapshot: action.snapshot,
        currentUserId: action.currentUserId,
        splitDraft: defaultSplitDraftForSnapshot(state, action.snapshot),
        syncState: "idle",
        message: null,
        rosterEditDrafts: Object.fromEntries(action.snapshot.trip_people.map((person) => [person.id, { displayName: person.display_name }])),
        splitGroupEditDrafts: Object.fromEntries(action.snapshot.split_groups.map((group) => [group.id, { name: group.name }])),
      };
    case "pendingLoaded":
      return { ...state, pendingMutations: action.pendingMutations };
    case "loadFailed":
      return { ...state, syncState: "failed", message: action.message };
    case "panelSelected":
      return { ...state, activePanel: action.panel };
    case "quickInputChanged":
      return { ...state, quickDraft: parseQuickExpense(action.value), message: null };
    case "quickDraftPrefilled":
      return { ...state, activePanel: "entry", quickDraft: parseQuickExpense(action.value), message: "Expense details copied into quick add." };
    case "quickSubmitStarted":
      return { ...state, syncState: "saving", pendingClientUuid: action.clientUuid, message: "Saving expense..." };
    case "quickSubmitSucceeded":
      return { ...state, syncState: "idle", pendingClientUuid: null, quickDraft: parseQuickExpense(""), message: "Expense saved." };
    case "quickSubmitRejected":
    case "quickSubmitFailed":
      return { ...state, syncState: "failed", pendingClientUuid: null, message: action.message };
    case "editStarted":
      return {
        ...state,
        editingExpenseId: action.expenseId,
        editDrafts: {
          ...state.editDrafts,
          [action.expenseId]: { amount: action.amount, description: action.description },
        },
        message: null,
      };
    case "editCancelled":
      return { ...state, editingExpenseId: null, message: null };
    case "editChanged":
      return {
        ...state,
        editDrafts: {
          ...state.editDrafts,
          [action.expenseId]: {
            amount: state.editDrafts[action.expenseId]?.amount || "",
            description: state.editDrafts[action.expenseId]?.description || "",
            [action.field]: action.value,
          },
        },
      };
    case "expenseMutationStarted":
      return { ...state, syncState: "saving", pendingClientUuid: action.clientUuid, message: "Saving change..." };
    case "expenseMutationSucceeded":
      return { ...state, syncState: "idle", pendingClientUuid: null, editingExpenseId: null, message: action.message };
    case "expenseMutationQueued":
      return { ...state, syncState: "idle", pendingClientUuid: null, editingExpenseId: null, message: action.message };
    case "expenseMutationFailed":
      return { ...state, syncState: "failed", pendingClientUuid: null, message: action.message };
    case "splitModeChanged":
      return { ...state, splitDraft: { ...state.splitDraft, mode: action.mode }, message: null };
    case "splitPersonToggled": {
      const selected = state.splitDraft.selectedTripPersonIds.includes(action.tripPersonId)
        ? state.splitDraft.selectedTripPersonIds.filter((id) => id !== action.tripPersonId)
        : [...state.splitDraft.selectedTripPersonIds, action.tripPersonId];
      return { ...state, splitDraft: { ...state.splitDraft, selectedTripPersonIds: selected }, message: null };
    }
    case "splitValueChanged":
      return {
        ...state,
        splitDraft: {
          ...state.splitDraft,
          values: { ...state.splitDraft.values, [action.tripPersonId]: action.value },
        },
        message: null,
      };
    case "splitPeopleSelected":
      return { ...state, splitDraft: { ...state.splitDraft, selectedTripPersonIds: action.tripPersonIds }, message: null };
    case "rosterDraftChanged":
      return { ...state, rosterDraft: { ...state.rosterDraft, [action.field]: action.value }, message: null };
    case "rosterDraftReset":
      return { ...state, rosterDraft: { displayName: "", email: "" }, message: null };
    case "rosterEditChanged":
      return {
        ...state,
        rosterEditDrafts: {
          ...state.rosterEditDrafts,
          [action.tripPersonId]: { displayName: action.value },
        },
        message: null,
      };
    case "splitGroupDraftChanged":
      return { ...state, splitGroupDraft: { name: action.value }, message: null };
    case "splitGroupDraftReset":
      return { ...state, splitGroupDraft: { name: "" }, message: null };
    case "splitGroupEditChanged":
      return {
        ...state,
        splitGroupEditDrafts: {
          ...state.splitGroupEditDrafts,
          [action.splitGroupId]: { name: action.value },
        },
        message: null,
      };
  }
}

function defaultSplitDraftForSnapshot(state: ExpenseAppState, snapshot: ExpenseSnapshot) {
  if (state.splitDraft.selectedTripPersonIds.length > 0) return state.splitDraft;

  return {
    ...state.splitDraft,
    selectedTripPersonIds: snapshot.trip_people.filter((person) => person.status !== "archived").map((person) => person.id),
  };
}

export function selectCurrentTripPerson(snapshot: ExpenseSnapshot, currentUserId: number): TripPerson | null {
  return snapshot.trip_people.find((person) => person.user_id === currentUserId) || snapshot.trip_people[0] || null;
}

export function splitEqual(amount: number, tripPeople: TripPerson[]) {
  const people = tripPeople.length > 0 ? tripPeople : [];
  if (people.length === 0) return [];

  const cents = Math.round(amount * 100);
  const base = Math.floor(cents / people.length);
  const remainder = cents - base * people.length;

  return people.map((person, index) => {
    const owedCents = base + (index < remainder ? 1 : 0);
    const amountOwed = (owedCents / 100).toFixed(2);

    return {
      trip_person_id: person.id,
      amount_owed: amountOwed,
      split_method: "exact",
      split_value: amountOwed,
      split_metadata: { generated_by: "quick_add_equal_split" },
    };
  });
}
