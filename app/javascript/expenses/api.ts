import type { ClientExpenseMutation, ExpenseSnapshot, SplitGroup, TripPerson } from "./types";

export async function fetchSnapshot(url: string): Promise<ExpenseSnapshot> {
  const response = await fetch(url, {
    headers: { Accept: "application/json" },
    credentials: "same-origin",
  });

  if (!response.ok) {
    throw new Error(`Snapshot request failed (${response.status}).`);
  }

  return response.json();
}

export class ExpenseSyncError extends Error {
  status: number;
  body: any;

  constructor(message: string, status: number, body: any) {
    super(message);
    this.name = "ExpenseSyncError";
    this.status = status;
    this.body = body;
  }
}

export async function submitExpenseMutation(url: string, mutation: ClientExpenseMutation) {
  const response = await fetch(url, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken(),
    },
    credentials: "same-origin",
    body: JSON.stringify({ client_mutation: mutation }),
  });

  const body = await response.json().catch(() => ({}));

  if (!response.ok || (body.status !== "accepted" && body.status !== "duplicate")) {
    throw new ExpenseSyncError(body?.error?.message || body?.error || `Sync failed (${response.status}).`, response.status, body);
  }

  return body;
}

export const submitExpenseCreate = submitExpenseMutation;

export async function createTripPerson(url: string, params: { display_name: string; email: string | null; status: string }): Promise<TripPerson> {
  return submitJson(url, "POST", { trip_person: params });
}

export async function updateTripPerson(url: string, id: number, params: { display_name: string }): Promise<TripPerson> {
  return submitJson(appendPathSegment(url, String(id)), "PATCH", { trip_person: params });
}

export async function createSplitGroup(url: string, params: { name: string; kind: string; trip_person_ids: number[] }): Promise<SplitGroup> {
  return submitJson(url, "POST", { split_group: params });
}

export async function updateSplitGroup(url: string, id: number, params: { name: string; trip_person_ids?: number[] }): Promise<SplitGroup> {
  return submitJson(appendPathSegment(url, String(id)), "PATCH", { split_group: params });
}

async function submitJson<T>(url: string, method: "POST" | "PATCH", body: unknown): Promise<T> {
  const response = await fetch(url, {
    method,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken(),
    },
    credentials: "same-origin",
    body: JSON.stringify(body),
  });

  const responseBody = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ExpenseSyncError(responseBody?.error?.message || responseBody?.error || `Request failed (${response.status}).`, response.status, responseBody);
  }

  return responseBody;
}

function csrfToken(): string {
  return document.querySelector<HTMLMetaElement>("meta[name='csrf-token']")?.content || "";
}

function appendPathSegment(url: string, segment: string): string {
  const [path, query] = url.split("?", 2);
  return `${path.replace(/\/$/, "")}/${encodeURIComponent(segment)}${query ? `?${query}` : ""}`;
}
