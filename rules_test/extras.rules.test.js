"use strict";
const fs = require("node:fs");
const path = require("node:path");
const { test, before, after, beforeEach } = require("node:test");
const { initializeTestEnvironment, assertSucceeds, assertFails } = require("@firebase/rules-unit-testing");
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, getDocs, query, where, limit,
  orderBy, writeBatch, arrayUnion, Bytes, serverTimestamp,
} = require("firebase/firestore");

let env;
const root = path.join(__dirname, "..");

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-paypact",
    firestore: { rules: fs.readFileSync(path.join(root, "firestore.rules"), "utf8") },
  });
});
after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "groups/g1"), {
      name: "Trip", createdBy: "alice", adminIds: ["alice"],
      memberIds: ["alice", "bob"], memberNames: { alice: "Alice", bob: "Bob" },
    });
    await setDoc(doc(db, "groups/g1/expenses/e1"), { title: "Dinner", createdById: "bob" });
    await setDoc(doc(db, "groups/g1/expenses/e1/comments/c1"), { authorId: "bob", text: "hi" });
    await setDoc(doc(db, "groups/g1/settlements/s1"), { amountPaise: 100, createdById: "bob" });
    await setDoc(doc(db, "groups/g1/recurring/r1"), { createdById: "alice", active: true });
    await setDoc(doc(db, "groups/g2"), {
      name: "Other", createdBy: "dave", adminIds: ["dave"], memberIds: ["dave"], memberNames: { dave: "Dave" },
    });
    await setDoc(doc(db, "invites/CODE1"), { groupId: "g1", name: "Trip", emoji: "✈️" });
    await setDoc(doc(db, "invites/CODE2"), { groupId: "g2", name: "Other", emoji: "🎉" });
    await setDoc(doc(db, "users/alice"), { name: "Alice", email: "a@x.com", nameLower: "alice" });
    await setDoc(doc(db, "users/bob"), { name: "Bob", email: "b@x.com", nameLower: "bob" });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();

// ── user enumeration ───────────────────────────────────────────────────────
test("users can be fetched by id but never listed or searched", async () => {
  await assertSucceeds(getDoc(doc(as("bob"), "users/alice")));
  await assertFails(getDocs(collection(as("bob"), "users")));
  await assertFails(getDocs(query(collection(as("bob"), "users"), where("email", "==", "a@x.com"))));
  await assertFails(getDocs(query(collection(as("bob"), "users"), where("nameLower", ">=", "a"))));
});

// ── running summary is maintained by the members ─────────────────────────────
test("members move the running balances; outsiders and non-admin edits are refused", async () => {
  await assertSucceeds(updateDoc(doc(as("bob"), "groups/g1"), {
    "balances.alice": 500, "balances.bob": -500, totalSpentMinor: 500, expenseCount: 1,
    lastActivityAt: serverTimestamp(), summaryVersion: 1, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(as("carol"), "groups/g1"), { "balances.alice": 1 }));
  // a summary write can't smuggle in anything else
  await assertFails(updateDoc(doc(as("bob"), "groups/g1"), { "balances.bob": 1, name: "Mine" }));
  // admins still edit details
  await assertSucceeds(updateDoc(doc(as("alice"), "groups/g1"), { name: "Goa", coverUrl: "fsimg:groups/g1/photos/cover#1" }));
});

test("a new group starts empty: no pre-filled totals", async () => {
  await assertFails(setDoc(doc(as("carol"), "groups/new"), {
    name: "X", createdBy: "carol", memberIds: ["carol"], totalSpentMinor: 5,
  }));
  await assertSucceeds(setDoc(doc(as("carol"), "groups/new2"), {
    name: "X", createdBy: "carol", memberIds: ["carol"], balances: { carol: 0 },
    totalSpentMinor: 0, expenseCount: 0, summaryVersion: 1,
  }));
});

test("a deleted group reads as missing; an existing one stays private", async () => {
  const missing = await assertSucceeds(getDoc(doc(as("carol"), "groups/nope")));
  if (missing.exists()) throw new Error("should not exist");
  await assertFails(getDoc(doc(as("carol"), "groups/g1")));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "groups/nope")));
});

// ── invite links ─────────────────────────────────────────────────────────────
test("invites: fetched by code, never listed", async () => {
  await assertSucceeds(getDoc(doc(as("carol"), "invites/CODE1")));
  await assertFails(getDocs(collection(as("carol"), "invites")));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "invites/CODE1")));
});

test("invites: only a group admin can publish or remove one", async () => {
  await assertSucceeds(setDoc(doc(as("alice"), "invites/NEWCODE"), { groupId: "g1", name: "Trip", emoji: "✈️" }));
  await assertFails(setDoc(doc(as("bob"), "invites/NEWCODE2"), { groupId: "g1", name: "Trip", emoji: "✈️" }));
  await assertFails(setDoc(doc(as("carol"), "invites/NEWCODE3"), { groupId: "g1", name: "Trip", emoji: "✈️" }));
  // can't hijack another group's code
  await assertFails(setDoc(doc(as("alice"), "invites/CODE2"), { groupId: "g1", name: "Trip", emoji: "✈️" }));
  await assertFails(deleteDoc(doc(as("bob"), "invites/CODE1")));
  await assertSucceeds(deleteDoc(doc(as("alice"), "invites/CODE1")));
});

test("invites: a new group can publish its invite in the same batch", async () => {
  const db = as("carol");
  const batch = writeBatch(db);
  batch.set(doc(db, "groups/fresh"), {
    name: "Fresh", createdBy: "carol", adminIds: ["carol"], memberIds: ["carol"],
    memberNames: { carol: "Carol" }, inviteCode: "FRESH123",
  });
  batch.set(doc(db, "invites/FRESH123"), { groupId: "fresh", name: "Fresh", emoji: "✨" });
  await assertSucceeds(batch.commit());
});

test("joining through an invite adds only yourself, with a code for this group", async () => {
  const g1 = (uid) => doc(as(uid), "groups/g1");
  const base = { updatedAt: serverTimestamp() };
  await assertSucceeds(updateDoc(g1("carol"), {
    memberIds: arrayUnion("carol"), "memberNames.carol": "Carol", joinCode: "CODE1", ...base,
  }));
  await assertSucceeds(getDoc(g1("carol"))); // now a member
});

test("joining is refused with the wrong code, no code, or on someone else's behalf", async () => {
  const g1 = (uid) => doc(as(uid), "groups/g1");
  // a code that belongs to a different group
  await assertFails(updateDoc(g1("carol"), {
    memberIds: arrayUnion("carol"), "memberNames.carol": "Carol", joinCode: "CODE2",
  }));
  // a code that doesn't exist
  await assertFails(updateDoc(g1("carol"), {
    memberIds: arrayUnion("carol"), "memberNames.carol": "Carol", joinCode: "NOPE1234",
  }));
  // no code at all
  await assertFails(updateDoc(g1("carol"), { memberIds: arrayUnion("carol"), "memberNames.carol": "Carol" }));
  // adding somebody else, or renaming an existing member, while joining
  await assertFails(updateDoc(g1("carol"), {
    memberIds: arrayUnion("carol", "erin"), "memberNames.carol": "Carol", joinCode: "CODE1",
  }));
  await assertFails(updateDoc(g1("carol"), {
    memberIds: arrayUnion("carol"), "memberNames.carol": "Carol", "memberNames.alice": "Hacked", joinCode: "CODE1",
  }));
  // promoting yourself on the way in
  await assertFails(updateDoc(g1("carol"), {
    memberIds: arrayUnion("carol"), "memberNames.carol": "Carol", joinCode: "CODE1", adminIds: ["alice", "carol"],
  }));
});

// ── people directory ─────────────────────────────────────────────────────────
test("directory: searchable in small pages, writable only by its owner", async () => {
  await assertSucceeds(setDoc(doc(as("alice"), "directory/alice"), {
    name: "Alice", nameLower: "alice", emailHash: "abc", emailMasked: "a••••@x.com", photoUrl: null,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(as("bob"), "directory/alice"), { name: "Evil", nameLower: "evil" }));
  await assertFails(setDoc(doc(as("alice"), "directory/alice"), { name: "Alice", email: "a@x.com" }));
  const dir = collection(as("bob"), "directory");
  await assertSucceeds(getDocs(query(dir, orderBy("nameLower"), limit(10))));
  await assertSucceeds(getDocs(query(dir, where("emailHash", "==", "abc"), limit(5))));
  await assertFails(getDocs(dir));                                       // unbounded
  await assertFails(getDocs(query(dir, orderBy("nameLower"), limit(100)))); // too big
  await assertFails(getDocs(query(collection(env.unauthenticatedContext().firestore(), "directory"), limit(5))));
});

// ── photos as documents ──────────────────────────────────────────────────────
const photo = (n = 1000) => ({ data: Bytes.fromUint8Array(new Uint8Array(n)), size: n, updatedAt: serverTimestamp() });

test("avatars: anyone signed in reads, only the owner writes, size is capped", async () => {
  await assertSucceeds(setDoc(doc(as("alice"), "users/alice/photos/avatar"), photo()));
  await assertFails(setDoc(doc(as("bob"), "users/alice/photos/avatar"), photo()));
  await assertSucceeds(getDoc(doc(as("bob"), "users/alice/photos/avatar")));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "users/alice/photos/avatar")));
  await assertFails(setDoc(doc(as("alice"), "users/alice/photos/avatar"), photo(800000)));
  await assertFails(setDoc(doc(as("alice"), "users/alice/photos/avatar"), { data: "not bytes", size: 1, updatedAt: serverTimestamp() }));
  await assertSucceeds(getDocs(collection(as("alice"), "users/alice/photos")));  // own list (account deletion)
  await assertFails(getDocs(collection(as("bob"), "users/alice/photos")));       // not someone else's
  await assertFails(deleteDoc(doc(as("bob"), "users/alice/photos/avatar")));
  await assertSucceeds(deleteDoc(doc(as("alice"), "users/alice/photos/avatar")));
});

test("group photos: members only; the cover is for admins", async () => {
  await assertSucceeds(setDoc(doc(as("bob"), "groups/g1/photos/receipt_1"), photo()));
  await assertFails(setDoc(doc(as("carol"), "groups/g1/photos/receipt_2"), photo()));
  await assertSucceeds(getDoc(doc(as("alice"), "groups/g1/photos/receipt_1")));
  await assertFails(getDoc(doc(as("carol"), "groups/g1/photos/receipt_1")));
  await assertFails(setDoc(doc(as("bob"), "groups/g1/photos/cover"), photo()));
  await assertSucceeds(setDoc(doc(as("alice"), "groups/g1/photos/cover"), photo()));
  await assertFails(deleteDoc(doc(as("bob"), "groups/g1/photos/cover")));
  await assertFails(setDoc(doc(as("bob"), "groups/g1/photos/receipt_3"), photo(800000)));
});

// ── deleting a group removes its ledger ──────────────────────────────────────
test("the ledger can only be removed once the group is marked deleting", async () => {
  await assertFails(deleteDoc(doc(as("alice"), "groups/g1/settlements/s1")));
  await assertFails(deleteDoc(doc(as("alice"), "groups/g1/expenses/e1/comments/c1"))); // not the author
  await assertFails(updateDoc(doc(as("bob"), "groups/g1"), { deleting: true }));      // admins only
  await assertSucceeds(updateDoc(doc(as("alice"), "groups/g1"), { deleting: true }));
  await assertFails(updateDoc(doc(as("alice"), "groups/g1"), { deleting: false }));   // one-way
  await assertSucceeds(deleteDoc(doc(as("alice"), "groups/g1/settlements/s1")));
  await assertSucceeds(deleteDoc(doc(as("alice"), "groups/g1/expenses/e1/comments/c1")));
  await assertFails(deleteDoc(doc(as("carol"), "groups/g1/settlements/s1")));
});

// ── recurring expenses created on the owner's behalf ─────────────────────────
test("any member can create a due recurring expense for the template's owner", async () => {
  const exp = (uid) => collection(as(uid), "groups/g1/expenses");
  await assertSucceeds(addDoc(exp("bob"), { title: "Rent", createdById: "alice", recurringId: "r1" }));
  await assertFails(addDoc(exp("bob"), { title: "Rent", createdById: "alice" }));                    // no template
  await assertSucceeds(addDoc(exp("bob"), { title: "Mine", createdById: "bob", recurringId: "r1" })); // own entry
  await assertFails(addDoc(exp("bob"), { title: "Rent", createdById: "erin", recurringId: "r1" })); // wrong owner
  await assertFails(addDoc(exp("carol"), { title: "Rent", createdById: "alice", recurringId: "r1" })); // outsider
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
