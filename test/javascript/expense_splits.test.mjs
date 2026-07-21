import test from "node:test";
import assert from "node:assert/strict";
import { buildSplitPayload, createDefaultSplitDraft } from "../../tmp/expense_splits_test.js";

const people = [
  { id: 1, display_name: "Ada", email: null, status: "active", user_id: 1 },
  { id: 2, display_name: "Ben", email: null, status: "active", user_id: 2 },
];

test("builds equal splits with rounding", () => {
  const result = buildSplitPayload(10.01, people, createDefaultSplitDraft());

  assert.equal(result.error, null);
  assert.deepEqual(result.splits.map((split) => split.amount_owed), ["5.01", "5.00"]);
});

test("builds exact unequal splits", () => {
  const result = buildSplitPayload(100, people, {
    mode: "exact",
    selectedTripPersonIds: [1, 2],
    values: { 1: "70", 2: "30" },
  });

  assert.equal(result.error, null);
  assert.deepEqual(result.splits.map((split) => split.amount_owed), ["70.00", "30.00"]);
});

test("rejects exact splits that do not total the amount", () => {
  const result = buildSplitPayload(100, people, {
    mode: "exact",
    selectedTripPersonIds: [1, 2],
    values: { 1: "60", 2: "30" },
  });

  assert.equal(result.error, "Exact splits must add up to 100.00.");
});

test("builds shares and percentage splits", () => {
  const shares = buildSplitPayload(90, people, {
    mode: "shares",
    selectedTripPersonIds: [1, 2],
    values: { 1: "2", 2: "1" },
  });
  const percentages = buildSplitPayload(90, people, {
    mode: "percentage",
    selectedTripPersonIds: [1, 2],
    values: { 1: "25", 2: "75" },
  });

  assert.deepEqual(shares.splits.map((split) => split.amount_owed), ["60.00", "30.00"]);
  assert.deepEqual(percentages.splits.map((split) => split.amount_owed), ["22.50", "67.50"]);
});
