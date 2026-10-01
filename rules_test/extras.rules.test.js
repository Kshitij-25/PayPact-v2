"use strict";
const fs = require("node:fs");
const path = require("node:path");
const { test, before, after, beforeEach } = require("node:test");
const { initializeTestEnvironment, assertSucceeds, assertFails } = require("@firebase/rules-unit-testing");
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, getDocs, query, where,
} = require("firebase/firestore");
const { ref, uploadString, getBytes, deleteObject } = require("firebase/storage");

let env;
const root = path.join(__dirname, "..");

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-paypact",
    firestore: { rules: fs.readFileSync(path.join(root, "firestore.rules"), "utf8") },
    storage: { rules: fs.readFileSync(path.join(root, "storage.rules"), "utf8") },
  });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "groups/g1"), {
      name: "Trip", createdBy: "alice", adminIds: ["alice"],
      memberIds: ["alice", "bob"], memberNames: { alice: "Alice", bob: "Bob" },
    });
    await setDoc(doc(db, "groups/g1/expenses/e1"), { title: "Dinner", createdById: "bob" });
    await setDoc(doc(db, "groups/g1/expenses/e1/comments/c1"), { authorId: "bob", text: "hi" });
    await setDoc(doc(db, "users/alice"), { name: "Alice", email: "a@x.com", nameLower: "alice" });
    await setDoc(doc(db, "users/bob"), { name: "Bob", email: "b@x.com", nameLower: "bob" });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const st = (uid) => env.authenticatedContext(uid).storage();

// ── user enumeration ───────────────────────────────────────────────────────
test("users can be fetched by id but never listed or searched", async () => {
  await assertSucceeds(getDoc(doc(as("bob"), "users/alice")));
  await assertFails(getDocs(collection(as("bob"), "users")));
  await assertFails(getDocs(query(collection(as("bob"), "users"), where("email", "==", "a@x.com"))));
  await assertFails(getDocs(query(collection(as("bob"), "users"), where("nameLower", ">=", "a"))));
});

// ── summary fields are server-owned ────────────────────────────────────────
test("clients cannot forge group balances, even admins", async () => {
  await assertFails(updateDoc(doc(as("alice"), "groups/g1"), { balances: { alice: 999 } }));
  await assertFails(updateDoc(doc(as("alice"), "groups/g1"), { "balances.alice": 999 }));
  await assertFails(updateDoc(doc(as("alice"), "groups/g1"), { totalSpentMinor: 1 }));
  await assertFails(updateDoc(doc(as("alice"), "groups/g1"), { summaryVersion: 1 }));
  // ...while normal admin edits still work
  await assertSucceeds(updateDoc(doc(as("alice"), "groups/g1"), { name: "Goa", coverUrl: "https://x/y.jpg" }));
});

test("a new group cannot be created with a pre-filled summary", async () => {
  await assertFails(setDoc(doc(as("carol"), "groups/new"), {
    name: "X", createdBy: "carol", memberIds: ["carol"], balances: { carol: 5 },
  }));
  await assertSucceeds(setDoc(doc(as("carol"), "groups/new2"), {
    name: "X", createdBy: "carol", memberIds: ["carol"],
  }));
});

test("the _events ledger is invisible to clients", async () => {
  await assertFails(getDoc(doc(as("alice"), "groups/g1/_events/x")));
  await assertFails(setDoc(doc(as("alice"), "groups/g1/_events/x"), { a: 1 }));
});

// ── comments ───────────────────────────────────────────────────────────────
test("comments: members post as themselves; only the author deletes", async () => {
  const c = (uid) => collection(as(uid), "groups/g1/expenses/e1/comments");
  await assertSucceeds(addDoc(c("alice"), { authorId: "alice", text: "nice" }));
  await assertFails(addDoc(c("alice"), { authorId: "bob", text: "forged" }));
  await assertFails(addDoc(c("alice"), { authorId: "alice", text: "" }));
  await assertFails(addDoc(c("alice"), { authorId: "alice", text: "x".repeat(1001) }));
  await assertFails(addDoc(c("carol"), { authorId: "carol", text: "outsider" }));
  await assertSucceeds(getDocs(c("alice")));
  await assertFails(getDocs(c("carol")));

  await assertFails(updateDoc(doc(as("bob"), "groups/g1/expenses/e1/comments/c1"), { text: "edit" }));
  await assertFails(deleteDoc(doc(as("alice"), "groups/g1/expenses/e1/comments/c1")));
  await assertSucceeds(deleteDoc(doc(as("bob"), "groups/g1/expenses/e1/comments/c1")));
});

// ── history ────────────────────────────────────────────────────────────────
test("history is append-only and attributed to the writer", async () => {
  const h = (uid) => collection(as(uid), "groups/g1/expenses/e1/history");
  const entry = await assertSucceeds(addDoc(h("alice"), { by: "alice", changes: ["title"] }));
  await assertFails(addDoc(h("alice"), { by: "bob", changes: [] }));
  await assertFails(updateDoc(entry, { changes: [] }));
  await assertFails(deleteDoc(entry));
  await assertFails(getDocs(h("carol")));
});

// ── recurring ──────────────────────────────────────────────────────────────
test("recurring templates: members manage, outsiders locked out", async () => {
  const r = (uid) => collection(as(uid), "groups/g1/recurring");
  const t = await assertSucceeds(addDoc(r("alice"), { createdById: "alice", active: true, title: "Rent" }));
  await assertFails(addDoc(r("alice"), { createdById: "bob", active: true }));
  await assertFails(addDoc(r("carol"), { createdById: "carol", active: true }));
  await assertSucceeds(updateDoc(t, { active: false }));
  await assertFails(updateDoc(t, { createdById: "bob" }));
  await assertFails(getDocs(r("carol")));
  await assertSucceeds(deleteDoc(t));
});

// ── storage ────────────────────────────────────────────────────────────────
const png = "data:image/png;base64,iVBORw0KGgo=";

test("avatars: anyone signed in reads, only the owner writes their own file", async () => {
  await assertSucceeds(uploadString(ref(st("alice"), "avatars/alice.jpg"), png, "data_url"));
  await assertFails(uploadString(ref(st("bob"), "avatars/alice.jpg"), png, "data_url"));
  await assertSucceeds(getBytes(ref(st("bob"), "avatars/alice.jpg")));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), "avatars/alice.jpg")));
  await assertFails(uploadString(ref(st("alice"), "avatars/alice.jpg"), "plain text", "raw", { contentType: "text/plain" }));
  await assertFails(deleteObject(ref(st("bob"), "avatars/alice.jpg")));
  await assertSucceeds(deleteObject(ref(st("alice"), "avatars/alice.jpg")));
});

test("group files: members only, images only", async () => {
  await assertSucceeds(uploadString(ref(st("bob"), "groups/g1/cover.jpg"), png, "data_url"));
  await assertSucceeds(uploadString(ref(st("bob"), "groups/g1/receipts/e1.jpg"), png, "data_url"));
  await assertFails(uploadString(ref(st("carol"), "groups/g1/cover.jpg"), png, "data_url"));
  await assertFails(uploadString(ref(st("bob"), "groups/g1/doc.txt"), "hello", "raw", { contentType: "text/plain" }));
  await assertSucceeds(getBytes(ref(st("alice"), "groups/g1/cover.jpg")));
  await assertFails(getBytes(ref(st("carol"), "groups/g1/cover.jpg")));
});
