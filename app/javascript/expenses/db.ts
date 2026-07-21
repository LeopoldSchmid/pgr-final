import type { ExpenseSnapshot, PendingExpenseMutation } from "./types";

const DB_NAME = "plangoreminisce-expenses";
const DB_VERSION = 1;
const SNAPSHOT_STORE = "snapshots";
const PENDING_STORE = "pending_mutations";

export async function saveSnapshot(snapshot: ExpenseSnapshot) {
  const db = await openDb();
  await put(db, SNAPSHOT_STORE, snapshot, String(snapshot.trip.id));
}

export async function loadSnapshot(tripId: string): Promise<ExpenseSnapshot | null> {
  const db = await openDb();
  return get<ExpenseSnapshot>(db, SNAPSHOT_STORE, tripId);
}

export async function enqueuePendingMutation(mutation: PendingExpenseMutation) {
  const db = await openDb();
  await put(db, PENDING_STORE, mutation, mutation.client_uuid);
}

export async function loadPendingMutations(): Promise<PendingExpenseMutation[]> {
  const db = await openDb();
  return getAll<PendingExpenseMutation>(db, PENDING_STORE);
}

export async function removePendingMutation(clientUuid: string) {
  const db = await openDb();
  await deleteRecord(db, PENDING_STORE, clientUuid);
}

export async function updatePendingMutationError(
  clientUuid: string,
  message: string,
  syncStatus: PendingExpenseMutation["sync_status"] = "failed",
  conflict: unknown = null,
) {
  const pending = await loadPendingMutations();
  const entry = pending.find((mutation) => mutation.client_uuid === clientUuid);
  if (!entry) return;

  await enqueuePendingMutation({ ...entry, last_error: message, sync_status: syncStatus, conflict });
}

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(SNAPSHOT_STORE)) db.createObjectStore(SNAPSHOT_STORE);
      if (!db.objectStoreNames.contains(PENDING_STORE)) db.createObjectStore(PENDING_STORE);
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error || new Error("Could not open expense storage."));
  });
}

function transaction(db: IDBDatabase, store: string, mode: IDBTransactionMode) {
  return db.transaction(store, mode).objectStore(store);
}

function put(db: IDBDatabase, store: string, value: unknown, key: string) {
  return requestToPromise(transaction(db, store, "readwrite").put(value, key));
}

function get<T>(db: IDBDatabase, store: string, key: string): Promise<T | null> {
  return requestToPromise<T | undefined>(transaction(db, store, "readonly").get(key)).then((value) => value || null);
}

function getAll<T>(db: IDBDatabase, store: string): Promise<T[]> {
  return requestToPromise<T[]>(transaction(db, store, "readonly").getAll());
}

function deleteRecord(db: IDBDatabase, store: string, key: string) {
  return requestToPromise(transaction(db, store, "readwrite").delete(key));
}

function requestToPromise<T = unknown>(request: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error || new Error("Expense storage request failed."));
  });
}
