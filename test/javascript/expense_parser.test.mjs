import test from "node:test";
import assert from "node:assert/strict";
import { parseQuickExpense } from "../../tmp/expense_parser_test.js";

test("parses amount before description", () => {
  const draft = parseQuickExpense("43.20 pizza");

  assert.equal(draft.amount, 43.2);
  assert.equal(draft.description, "pizza");
  assert.equal(draft.currency, "EUR");
  assert.equal(draft.category, "food");
  assert.equal(draft.error, null);
});

test("parses German decimal comma and symbol", () => {
  const draft = parseQuickExpense("pizza 43,20 €");

  assert.equal(draft.amount, 43.2);
  assert.equal(draft.description, "pizza");
  assert.equal(draft.currency, "EUR");
});

test("parses leading currency symbol", () => {
  const draft = parseQuickExpense("€12 coffee");

  assert.equal(draft.amount, 12);
  assert.equal(draft.description, "coffee");
  assert.equal(draft.category, "food");
});

test("returns editable low-confidence draft without amount", () => {
  const draft = parseQuickExpense("museum tickets");

  assert.equal(draft.amount, null);
  assert.equal(draft.description, "museum tickets");
  assert.equal(draft.category, "activities");
  assert.equal(draft.confidence, "low");
  assert.equal(draft.error, "Add an amount.");
});
