import type { ExpenseCategory, QuickExpenseDraft } from "./types";

const CATEGORY_KEYWORDS: Array<[ExpenseCategory, RegExp]> = [
  ["food", /\b(pizza|restaurant|cafe|coffee|dinner|lunch|breakfast|bar|bakery|bier|essen)\b/i],
  ["transport", /\b(train|taxi|uber|gas|fuel|metro|bus|tram|bahn|zug|benzin)\b/i],
  ["accommodation", /\b(hotel|hostel|airbnb|apartment|unterkunft)\b/i],
  ["activities", /\b(museum|tour|ticket|tickets|entry|eintritt|kino)\b/i],
  ["shopping", /\b(supermarket|groceries|pharmacy|market|shop|dm|rewe|edeka|apotheke)\b/i],
];

const CURRENCY_BY_SYMBOL: Record<string, string> = {
  "€": "EUR",
  "$": "USD",
  "£": "GBP",
};

export function parseQuickExpense(raw: string): QuickExpenseDraft {
  const normalized = raw.trim().replace(/\s+/g, " ");
  const fallback = draft(raw, null, "EUR", "", "other", "low", null);

  if (!normalized) {
    return { ...fallback, error: null };
  }

  const amountMatch = normalized.match(/(?:^|\s)(?<currencyBefore>[€$£]|[A-Z]{3})?\s*(?<amount>\d+(?:[.,]\d{1,2})?)(?:\s*(?<currencyAfter>[€$£]|[A-Z]{3}))?(?=\s|$)/);
  if (!amountMatch?.groups?.amount) {
    return draft(raw, null, "EUR", normalized, inferCategory(normalized), "low", "Add an amount.");
  }

  const currencyToken = amountMatch.groups.currencyBefore || amountMatch.groups.currencyAfter || "EUR";
  const currency = normalizeCurrency(currencyToken);
  const amount = parseAmount(amountMatch.groups.amount);
  const description = normalized.replace(amountMatch[0], " ").replace(/\s+/g, " ").trim();

  if (!amount || amount <= 0) {
    return draft(raw, null, currency, description, inferCategory(description), "low", "Use an amount greater than zero.");
  }

  return draft(
    raw,
    amount,
    currency,
    description,
    inferCategory(description),
    description.length > 0 ? "high" : "medium",
    description.length > 0 ? null : "Add a description.",
  );
}

function parseAmount(value: string): number | null {
  const decimal = value.replace(",", ".");
  const amount = Number.parseFloat(decimal);
  return Number.isFinite(amount) ? Math.round(amount * 100) / 100 : null;
}

function normalizeCurrency(value: string): string {
  const trimmed = value.trim().toUpperCase();
  return CURRENCY_BY_SYMBOL[value] || (trimmed.length === 3 ? trimmed : "EUR");
}

function inferCategory(description: string): ExpenseCategory {
  for (const [category, pattern] of CATEGORY_KEYWORDS) {
    if (pattern.test(description)) return category;
  }

  return "other";
}

function draft(
  raw: string,
  amount: number | null,
  currency: string,
  description: string,
  category: ExpenseCategory,
  confidence: QuickExpenseDraft["confidence"],
  error: string | null,
): QuickExpenseDraft {
  return { raw, amount, currency, description, category, confidence, error };
}
