import { expect, test } from "@playwright/test";
import { execFileSync } from "node:child_process";

test.describe.configure({ mode: "serial" });

test.afterAll(() => {
  execFileSync("bin/rails", ["db:test:purge", "db:test:prepare"], {
    env: { ...process.env, RAILS_ENV: "test" },
    stdio: "inherit",
  });
});

async function signInAndOpenExpenses(page) {
  await page.goto("/en/session/new");
  await page.locator("input[name='email_address']").fill("expense-e2e@example.com");
  await page.locator("input[name='password']").fill("password");
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.locator("body")).toContainText("Welcome back!");

  await page.goto("/en/select_trip?return_to=/en/expenses");
  await page.locator("div", { has: page.getByRole("heading", { name: "Playwright Expense Trip" }) }).getByRole("button").first().click();

  await expect(page.getByTestId("expense-app")).toBeVisible();
  await expect(page.getByTestId("expense-sync-state")).toContainText("Synced", { timeout: 15_000 });
}

async function createSyncedExpense(page, quickText: string, expectedDescription: string) {
  await fillQuickExpense(page, quickText);
  const mutationResponse = page.waitForResponse((response) =>
    response.url().includes("expense_client_mutations") && response.request().method() === "POST",
  );
  await page.getByTestId("expense-quick-submit").click();
  expect((await mutationResponse).ok()).toBe(true);
  await openExpensePanel(page, "History");
  await expect(page.getByTestId("expense-list")).toContainText(expectedDescription);
}

async function openExpensePanel(page, name: "Add" | "People" | "Balances" | "History") {
  await page.getByRole("link", { name, exact: true }).click();
  await expect(page.getByTestId("expense-app")).toBeVisible();
}

async function fillQuickExpense(page, quickText: string) {
  const [amount, ...descriptionParts] = quickText.split(" ");
  await page.getByTestId("expense-amount-input").fill(amount);
  await page.getByTestId("expense-quick-input").fill(descriptionParts.join(" "));
}

function expenseRow(page, description: string) {
  return page.getByTestId("expense-list").locator("article").filter({ hasText: description }).first();
}

async function splitGroupIdByName(page, name: string) {
  await expect.poll(async () => page.getByTestId("expense-groups").locator("[data-expense-group-edit]").evaluateAll((nodes, expectedName) => {
    const input = nodes.find((node) => (node as HTMLInputElement).value === expectedName) as HTMLInputElement | undefined;
    return input ? Number(input.dataset.expenseGroupEdit) : null;
  }, name)).not.toBeNull();

  return page.getByTestId("expense-groups").locator("[data-expense-group-edit]").evaluateAll((nodes, expectedName) => {
    const input = nodes.find((node) => (node as HTMLInputElement).value === expectedName) as HTMLInputElement | undefined;
    return Number(input?.dataset.expenseGroupEdit);
  }, name);
}

async function rosterPersonIdByName(page, name: string) {
  await expect.poll(async () => page.getByTestId("expense-roster").locator("[data-expense-roster-edit]").evaluateAll((nodes, expectedName) => {
    const input = nodes.find((node) => (node as HTMLInputElement).value === expectedName) as HTMLInputElement | undefined;
    return input ? Number(input.dataset.expenseRosterEdit) : null;
  }, name)).not.toBeNull();

  return page.getByTestId("expense-roster").locator("[data-expense-roster-edit]").evaluateAll((nodes, expectedName) => {
    const input = nodes.find((node) => (node as HTMLInputElement).value === expectedName) as HTMLInputElement | undefined;
    return Number(input?.dataset.expenseRosterEdit);
  }, name);
}

async function splitPersonIds(page) {
  const ids = await page.locator("[data-expense-split-person]").evaluateAll((nodes) =>
    nodes.map((node) => Number((node as HTMLInputElement).dataset.expenseSplitPerson)),
  );
  expect(ids.length).toBeGreaterThanOrEqual(2);
  return ids;
}

async function setSplitPersonChecked(page, personId: number, checked: boolean) {
  await page.getByTestId(`expense-split-person-${personId}`).evaluate((node, value) => {
    const input = node as HTMLInputElement;
    input.checked = value;
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }, checked);
}

async function waitForServiceWorker(page) {
  const controlled = await page.evaluate(async () => {
    if (!("serviceWorker" in navigator)) throw new Error("Service worker is not available.");
    await navigator.serviceWorker.register("/service-worker");
    const registration = await navigator.serviceWorker.ready;
    if (!registration.active) throw new Error("Service worker is not active.");
    return Boolean(navigator.serviceWorker.controller);
  });

  if (!controlled) {
    await page.reload();
    await page.evaluate(async () => {
      await navigator.serviceWorker.ready;
      if (!navigator.serviceWorker.controller) throw new Error("Service worker did not control the page after reload.");
    });
  }
}

test("expense entry fields and inferred context update in the browser", async ({ page }) => {
  await signInAndOpenExpenses(page);

  await fillQuickExpense(page, "43.20 pizza");

  await expect(page.getByTestId("expense-amount-input")).toHaveValue("43.20");
  await expect(page.getByTestId("expense-quick-input")).toHaveValue("pizza");
  await expect(page.getByTestId("expense-quick-preview")).toContainText("food");
});

test("quick-add input keeps focus while typing", async ({ page }) => {
  await signInAndOpenExpenses(page);

  const quickInput = page.getByTestId("expense-quick-input");
  await quickInput.focus();
  await page.keyboard.type("pizza", { delay: 5 });

  await expect(quickInput).toBeFocused();
  await expect(quickInput).toHaveValue("pizza");
});

test("quick-add create is queued when sync request fails and survives reload", async ({ page }) => {
  let interceptedMutation = false;
  await page.route("**/*expense_client_mutations*", (route) => {
    interceptedMutation = true;
    return route.abort("internetdisconnected");
  });
  await signInAndOpenExpenses(page);

  await fillQuickExpense(page, "12 coffee");
  await page.getByTestId("expense-quick-submit").click();

  await expect(page.getByTestId("expense-pending-list")).toBeVisible();
  expect(interceptedMutation).toBe(true);
  await expect(page.getByTestId("expense-pending-list")).toContainText("coffee");
  await expect(page.getByTestId("expense-pending-list")).toContainText("12.00 EUR");

  await page.reload();

  await expect(page.getByTestId("expense-pending-list")).toBeVisible();
  await expect(page.getByTestId("expense-pending-list")).toContainText("coffee");
});

test("synced expense edit is queued when mutation request fails and survives reload", async ({ page }) => {
  await signInAndOpenExpenses(page);
  await createSyncedExpense(page, "30 dinner", "dinner");

  await page.route("**/*expense_client_mutations*", (route) => route.abort("internetdisconnected"));
  await expenseRow(page, "dinner").getByRole("button", { name: "Edit" }).click();
  await page.getByTestId(/^expense-edit-description-/).fill("offline dinner");
  await page.getByTestId(/^expense-edit-amount-/).fill("31.50");
  await page.getByTestId(/^expense-edit-save-/).click();

  await expect(page.getByTestId("expense-pending-list")).toContainText("Edit expense");
  await expect(page.getByTestId("expense-pending-list")).toContainText("pending");

  await page.reload();

  await expect(page.getByTestId("expense-pending-list")).toContainText("Edit expense");
});

test("synced expense void is queued when mutation request fails and survives reload", async ({ page }) => {
  await signInAndOpenExpenses(page);
  await createSyncedExpense(page, "8 gelato", "gelato");

  await page.route("**/*expense_client_mutations*", (route) => route.abort("internetdisconnected"));
  await expenseRow(page, "gelato").getByRole("button", { name: "Void" }).click();

  await expect(page.getByTestId("expense-pending-list")).toContainText("Void expense");
  await expect(page.getByTestId("expense-pending-list")).toContainText("pending");

  await page.reload();

  await expect(page.getByTestId("expense-pending-list")).toContainText("Void expense");
});

test("conflict response is shown as a pending conflict state", async ({ page }) => {
  await signInAndOpenExpenses(page);
  await createSyncedExpense(page, "19 taxi", "taxi");

  await page.route("**/*expense_client_mutations*", (route) => route.fulfill({
    status: 409,
    contentType: "application/json",
    body: JSON.stringify({
      status: "conflict",
      conflict: true,
      error: { message: "expense changed on server" },
    }),
  }));

  await expenseRow(page, "taxi").getByRole("button", { name: "Edit" }).click();
  await page.getByTestId(/^expense-edit-description-/).fill("airport taxi");
  await page.getByTestId(/^expense-edit-save-/).click();

  await expect(page.getByTestId("expense-pending-list")).toContainText("conflict");
  await expect(page.getByTestId("expense-pending-list")).toContainText("expense changed on server");
});

test("quick-add supports exact unequal split preview and save", async ({ page }) => {
  await signInAndOpenExpenses(page);
  const [firstId, secondId] = await splitPersonIds(page);

  await fillQuickExpense(page, "100 dinner");
  await page.getByTestId("expense-split-mode").selectOption("exact");
  await page.getByTestId(`expense-split-value-${firstId}`).fill("70");
  await page.getByTestId(`expense-split-value-${secondId}`).fill("30");

  await expect(page.getByTestId(`expense-split-preview-${firstId}`)).toContainText("70.00");
  await expect(page.getByTestId(`expense-split-preview-${secondId}`)).toContainText("30.00");

  await page.getByTestId("expense-quick-submit").click();
  await openExpensePanel(page, "History");
  await expect(page.getByTestId("expense-list")).toContainText("dinner");
  await expect(expenseRow(page, "dinner")).toContainText("2 people");
});

test("balances, settlement suggestions, activity, and duplicate shortcut update after save", async ({ page }) => {
  await signInAndOpenExpenses(page);
  await createSyncedExpense(page, "45 lunch", "lunch");

  await expect(page.getByTestId("expense-activity")).toContainText("Added: lunch");
  await expenseRow(page, "lunch").getByRole("button", { name: "Copy" }).click();
  await expect(page.getByTestId("expense-amount-input")).toHaveValue("45.00");
  await expect(page.getByTestId("expense-quick-input")).toHaveValue("lunch");

  await openExpensePanel(page, "Balances");
  await expect(page.getByTestId("expense-balances")).toContainText("expense-e2e");
  await expect(page.getByTestId("expense-balances")).toContainText("EUR");
  await expect(page.getByTestId("expense-settlements")).toContainText("pays");
});

test("split editor validates exact split totals", async ({ page }) => {
  await signInAndOpenExpenses(page);
  const [firstId, secondId] = await splitPersonIds(page);

  await fillQuickExpense(page, "100 hotel");
  await page.getByTestId("expense-split-mode").selectOption("exact");
  await page.getByTestId(`expense-split-value-${firstId}`).fill("60");
  await page.getByTestId(`expense-split-value-${secondId}`).fill("30");
  await page.getByTestId("expense-quick-submit").click();

  await expect(page.getByTestId("expense-split-error")).toContainText("Exact splits must add up to 100.00.");
});

test("split editor supports shares and percentage previews", async ({ page }) => {
  await signInAndOpenExpenses(page);
  const [firstId, secondId] = await splitPersonIds(page);

  await fillQuickExpense(page, "90 taxi");
  await page.getByTestId("expense-split-mode").selectOption("shares");
  await page.getByTestId(`expense-split-value-${firstId}`).fill("2");
  await page.getByTestId(`expense-split-value-${secondId}`).fill("1");
  await expect(page.getByTestId(`expense-split-preview-${firstId}`)).toContainText("60.00");
  await expect(page.getByTestId(`expense-split-preview-${secondId}`)).toContainText("30.00");

  await page.getByTestId("expense-split-mode").selectOption("percentage");
  await page.getByTestId(`expense-split-value-${firstId}`).fill("25");
  await page.getByTestId(`expense-split-value-${secondId}`).fill("75");
  await expect(page.getByTestId(`expense-split-preview-${firstId}`)).toContainText("22.50");
  await expect(page.getByTestId(`expense-split-preview-${secondId}`)).toContainText("67.50");
});

test("traveler can be added from the expense flow and used immediately in a split", async ({ page }) => {
  await signInAndOpenExpenses(page);
  await openExpensePanel(page, "People");

  await page.getByTestId("expense-roster-name").fill("Late Joiner");
  await page.getByTestId("expense-roster-add").click();

  const lateJoinerId = await rosterPersonIdByName(page, "Late Joiner");

  await openExpensePanel(page, "Add");
  await expect(page.getByTestId(`expense-split-person-${lateJoinerId}`)).toBeChecked();
  await fillQuickExpense(page, "60 snacks");
  await page.getByTestId("expense-split-mode").selectOption("exact");
  await page.getByTestId(`expense-split-value-${lateJoinerId}`).fill("20");

  await expect(page.getByTestId(`expense-split-preview-${lateJoinerId}`)).toContainText("20.00");
});

test("traveler display name can be edited inline", async ({ page }) => {
  await signInAndOpenExpenses(page);
  const [firstId] = await splitPersonIds(page);
  await openExpensePanel(page, "People");

  await page.getByTestId(`expense-roster-display-name-${firstId}`).fill("Renamed Traveler");
  await expect(page.getByTestId(`expense-roster-save-${firstId}`)).toBeEnabled();
  const updateResponse = page.waitForResponse((response) =>
    response.url().includes(`/trip_people`) &&
    response.request().method() === "PATCH",
  );
  await page.getByTestId(`expense-roster-save-${firstId}`).click();
  const response = await updateResponse;
  expect(response.ok(), `${response.status()} ${response.url()}`).toBe(true);

  await expect(page.getByTestId(`expense-roster-display-name-${firstId}`)).toHaveValue("Renamed Traveler");
  await openExpensePanel(page, "Add");
  await expect(page.getByTestId(`expense-split-person-${firstId}`).locator("..")).toContainText("Renamed Traveler");
});

test("split group can be created from selected people and applied later", async ({ page }) => {
  await signInAndOpenExpenses(page);
  const [firstId, secondId] = await splitPersonIds(page);

  await openExpensePanel(page, "People");
  await page.getByTestId("expense-group-name").fill("Drivers");
  await page.getByTestId("expense-group-create").click();

  const groupId = await splitGroupIdByName(page, "Drivers");

  await openExpensePanel(page, "Add");
  await setSplitPersonChecked(page, firstId, false);
  await setSplitPersonChecked(page, secondId, false);
  await page.getByTestId(`expense-split-group-apply-${groupId}`).click();

  await expect(page.getByTestId(`expense-split-person-${firstId}`)).toBeChecked();
  await expect(page.getByTestId(`expense-split-person-${secondId}`)).toBeChecked();
});

test("split group can be renamed inline", async ({ page }) => {
  await signInAndOpenExpenses(page);
  await openExpensePanel(page, "People");
  await page.getByTestId("expense-group-name").fill("Camp cooks");
  await page.getByTestId("expense-group-create").click();

  const groupId = await splitGroupIdByName(page, "Camp cooks");

  await page.getByTestId(`expense-group-rename-${groupId}`).fill("Kitchen crew");
  const updateResponse = page.waitForResponse((response) =>
    response.url().includes("/split_groups") &&
    response.request().method() === "PATCH",
  );
  await page.getByTestId(`expense-group-save-${groupId}`).click();
  const response = await updateResponse;
  expect(response.ok(), `${response.status()} ${response.url()}`).toBe(true);

  await expect(page.getByTestId(`expense-group-rename-${groupId}`)).toHaveValue("Kitchen crew");
});

test("expense app shell reloads while offline after prior online use", async ({ page, context }) => {
  await signInAndOpenExpenses(page);
  await waitForServiceWorker(page);

  await page.reload();
  await expect(page.getByTestId("expense-app")).toBeVisible();
  await expect(page.getByTestId("expense-sync-state")).toContainText("Synced", { timeout: 15_000 });

  await context.setOffline(true);
  await page.reload({ waitUntil: "domcontentloaded" });

  await expect(page.getByTestId("expense-app")).toBeVisible();
  await expect(page.getByRole("link", { name: "Playwright Expense Trip" }).first()).toBeVisible();
  await expect(page.getByTestId("expense-sync-state")).toBeVisible();

  await context.setOffline(false);
});

test("primary expense workflow is usable on a phone viewport without horizontal overflow", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await signInAndOpenExpenses(page);

  await fillQuickExpense(page, "18 coffee");
  await expect(page.getByTestId("expense-amount-input")).toHaveValue("18.00");
  await expect(page.getByTestId("expense-split-editor")).toBeVisible();
  let hasHorizontalOverflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
  expect(hasHorizontalOverflow).toBe(false);

  await openExpensePanel(page, "People");
  await expect(page.getByTestId("expense-roster-groups")).toBeVisible();
  hasHorizontalOverflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
  expect(hasHorizontalOverflow).toBe(false);

  await openExpensePanel(page, "Balances");
  await expect(page.getByTestId("expense-ledger-summary")).toBeVisible();
  hasHorizontalOverflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
  expect(hasHorizontalOverflow).toBe(false);
});
