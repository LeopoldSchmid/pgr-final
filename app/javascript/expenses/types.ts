export type TripPerson = {
  id: number;
  display_name: string;
  email: string | null;
  status: string;
  user_id: number | null;
};

export type SplitGroup = {
  id: number;
  name: string;
  kind: string;
  trip_person_ids: number[];
};

export type ExpenseSplit = {
  trip_person_id: number;
  amount_owed: string;
  split_method: "equal" | "exact" | "shares" | "percentage";
  split_value: string | null;
  split_metadata: Record<string, unknown>;
};

export type ExpenseRecord = {
  id: number;
  amount: string;
  description: string;
  category: ExpenseCategory;
  currency: string;
  expense_date: string;
  status: string;
  lock_version: number;
  payer_trip_person_id: number;
  splits: ExpenseSplit[];
};

export type Balance = {
  trip_person_id: number;
  amount: string;
};

export type SettlementSuggestion = {
  from_trip_person_id: number;
  to_trip_person_id: number;
  amount: string;
  currency: string;
};

export type ExpenseSnapshot = {
  trip: {
    id: number;
    name: string;
  };
  trip_people: TripPerson[];
  split_groups: SplitGroup[];
  expenses: ExpenseRecord[];
  balances: Balance[];
  settlement_suggestions: SettlementSuggestion[];
};

export type ExpenseCategory = "food" | "accommodation" | "transport" | "activities" | "shopping" | "other";

export type QuickExpenseDraft = {
  raw: string;
  amount: number | null;
  currency: string;
  description: string;
  category: ExpenseCategory;
  confidence: "high" | "medium" | "low";
  error: string | null;
};

export type SyncState = "idle" | "loading" | "saving" | "failed";
export type ExpensePanel = "entry" | "people" | "summary" | "activity";

export type ExpenseAppState = {
  snapshot: ExpenseSnapshot | null;
  currentUserId: number | null;
  activePanel: ExpensePanel;
  syncState: SyncState;
  message: string | null;
  quickDraft: QuickExpenseDraft;
  pendingClientUuid: string | null;
  pendingMutations: PendingExpenseMutation[];
  editingExpenseId: number | null;
  editDrafts: Record<number, ExpenseEditDraft>;
  splitDraft: SplitDraft;
  rosterDraft: RosterDraft;
  rosterEditDrafts: Record<number, RosterEditDraft>;
  splitGroupDraft: SplitGroupDraft;
  splitGroupEditDrafts: Record<number, SplitGroupEditDraft>;
};

export type ExpenseCreatePayload = {
  expense: {
    client_uuid: string;
    amount: string;
    description: string;
    category: ExpenseCategory;
    currency: string;
    expense_date: string;
    payer_trip_person_id: number;
  };
  splits: Array<{
    trip_person_id: number;
    amount_owed: string;
    split_method: "equal" | "exact" | "shares" | "percentage";
    split_value: string;
    split_metadata: Record<string, unknown>;
  }>;
};

export type ClientExpenseCreateMutation = {
  client_uuid: string;
  mutation_type: "expense_create";
  payload: ExpenseCreatePayload;
};

export type ExpenseUpdatePayload = {
  expense_id: number;
  base_revision: number;
  expense: {
    amount?: string;
    description?: string;
    category?: ExpenseCategory;
    currency?: string;
    expense_date?: string;
    status?: string;
    payer_trip_person_id?: number;
  };
  splits?: ExpenseCreatePayload["splits"];
};

export type ExpenseVoidPayload = {
  expense_id: number;
  base_revision: number;
};

export type ClientExpenseUpdateMutation = {
  client_uuid: string;
  mutation_type: "expense_update";
  payload: ExpenseUpdatePayload;
};

export type ClientExpenseVoidMutation = {
  client_uuid: string;
  mutation_type: "expense_void";
  payload: ExpenseVoidPayload;
};

export type ClientExpenseMutation =
  | ClientExpenseCreateMutation
  | ClientExpenseUpdateMutation
  | ClientExpenseVoidMutation;

export type PendingExpenseMutation = ClientExpenseMutation & {
  queued_at: string;
  last_error: string | null;
  sync_status: "pending" | "failed" | "conflict" | "rejected";
  conflict: unknown | null;
};

export type ExpenseEditDraft = {
  amount: string;
  description: string;
};

export type SplitMode = "equal" | "exact" | "shares" | "percentage";

export type SplitDraft = {
  mode: SplitMode;
  selectedTripPersonIds: number[];
  values: Record<number, string>;
};

export type SplitPreview = {
  trip_person_id: number;
  display_name: string;
  amount_owed: string;
  split_method: SplitMode;
  split_value: string | null;
};

export type SplitBuildResult = {
  splits: ExpenseCreatePayload["splits"];
  preview: SplitPreview[];
  error: string | null;
};

export type RosterDraft = {
  displayName: string;
  email: string;
};

export type RosterEditDraft = {
  displayName: string;
};

export type SplitGroupDraft = {
  name: string;
};

export type SplitGroupEditDraft = {
  name: string;
};
