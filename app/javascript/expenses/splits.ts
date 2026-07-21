import type { ExpenseCreatePayload, SplitBuildResult, SplitDraft, SplitMode, TripPerson } from "./types";

export function createDefaultSplitDraft(): SplitDraft {
  return {
    mode: "equal",
    selectedTripPersonIds: [],
    values: {},
  };
}

export function ensureSplitSelection(draft: SplitDraft, tripPeople: TripPerson[]): SplitDraft {
  if (draft.selectedTripPersonIds.length > 0) return draft;
  return {
    ...draft,
    selectedTripPersonIds: tripPeople.filter((person) => person.status !== "archived").map((person) => person.id),
  };
}

export function buildSplitPayload(amount: number, tripPeople: TripPerson[], draft: SplitDraft): SplitBuildResult {
  const activeDraft = ensureSplitSelection(draft, tripPeople);
  const selected = tripPeople.filter((person) => activeDraft.selectedTripPersonIds.includes(person.id));

  if (selected.length === 0) {
    return { splits: [], preview: [], error: "Select at least one person." };
  }

  if (activeDraft.mode === "equal") return equalSplits(amount, selected);
  if (activeDraft.mode === "exact") return exactSplits(amount, selected, activeDraft);
  if (activeDraft.mode === "shares") return weightedSplits(amount, selected, activeDraft, "shares");
  return weightedSplits(amount, selected, activeDraft, "percentage");
}

function equalSplits(amount: number, people: TripPerson[]): SplitBuildResult {
  const cents = Math.round(amount * 100);
  const base = Math.floor(cents / people.length);
  const remainder = cents - base * people.length;

  const splits = people.map((person, index) => {
    const owed = centsToMoney(base + (index < remainder ? 1 : 0));
    return split(person, owed, "equal", null);
  });

  return result(splits, people, "equal", null);
}

function exactSplits(amount: number, people: TripPerson[], draft: SplitDraft): SplitBuildResult {
  const splits = people.map((person) => split(person, normalizeMoney(draft.values[person.id] || "0"), "exact", normalizeMoney(draft.values[person.id] || "0")));
  const total = splits.reduce((sum, entry) => sum + Math.round(Number(entry.amount_owed) * 100), 0);
  const expected = Math.round(amount * 100);
  const error = total === expected ? null : `Exact splits must add up to ${amount.toFixed(2)}.`;
  return result(splits, people, "exact", null, error);
}

function weightedSplits(amount: number, people: TripPerson[], draft: SplitDraft, mode: "shares" | "percentage"): SplitBuildResult {
  const weights = people.map((person) => Math.max(0, Number.parseFloat((draft.values[person.id] || "0").replace(",", ".")) || 0));
  const totalWeight = weights.reduce((sum, value) => sum + value, 0);

  if (totalWeight <= 0) {
    return { splits: [], preview: [], error: mode === "shares" ? "Enter at least one share." : "Enter at least one percentage." };
  }

  if (mode === "percentage" && Math.round(totalWeight * 100) !== 10000) {
    return { splits: [], preview: [], error: "Percentages must add up to 100." };
  }

  const totalCents = Math.round(amount * 100);
  let assigned = 0;
  const raw = people.map((person, index) => {
    const cents = index === people.length - 1 ? totalCents - assigned : Math.round((totalCents * weights[index]) / totalWeight);
    assigned += cents;
    return split(person, centsToMoney(cents), mode, String(weights[index]));
  });

  return result(raw, people, mode, null);
}

function split(person: TripPerson, amountOwed: string, method: SplitMode, value: string | null): ExpenseCreatePayload["splits"][number] {
  return {
    trip_person_id: person.id,
    amount_owed: amountOwed,
    split_method: method === "equal" ? "exact" : method,
    split_value: value || amountOwed,
    split_metadata: { generated_by: `split_editor_${method}` },
  };
}

function result(
  splits: ExpenseCreatePayload["splits"],
  people: TripPerson[],
  method: SplitMode,
  _value: string | null,
  error: string | null = null,
): SplitBuildResult {
  return {
    splits,
    preview: splits.map((entry) => ({
      trip_person_id: entry.trip_person_id,
      display_name: people.find((person) => person.id === entry.trip_person_id)?.display_name || "Unknown",
      amount_owed: entry.amount_owed,
      split_method: method,
      split_value: entry.split_value,
    })),
    error,
  };
}

function normalizeMoney(value: string): string {
  const parsed = Number.parseFloat(value.replace(",", "."));
  return Number.isFinite(parsed) ? parsed.toFixed(2) : "0.00";
}

function centsToMoney(cents: number): string {
  return (cents / 100).toFixed(2);
}
