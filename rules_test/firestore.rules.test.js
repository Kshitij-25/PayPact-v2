"use strict";
const fs = require("node:fs");
const path = require("node:path");
const { test, before, after, beforeEach } = require("node:test");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, getDocs,
  query, where, arrayUnion, serverTimestamp,
} = require("firebase/firestore");

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-paypact",
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8"),
    },
    storage: {
      rules: fs.readFileSync(path.join(__dirname, "..", "storage.rules"), "utf8"),
    },
  });
});
after(async () => env.cleanup());

// alice = admin/creator, bob = member, carol = outsider
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "groups/g1"), {
      name: "Trip", emoji: "🏖", category: "trip", currency: "INR",
      createdBy: "alice", adminIds: ["alice"],
      memberIds: ["alice", "bob"], memberNames: { alice: "Alice", bob: "Bob" },
      inviteCode: "ABCD1234",
    });
    // legacy group: no adminIds field at all
    await setDoc(doc(db, "groups/legacy"), {
      name: "Old", createdBy: "alice",
      memberIds: ["alice", "bob"], memberNames: { alice: "Alice", bob: "Bob" },
    });
    await setDoc(doc(db, "groups/g1/expenses/e1"), {
      title: "Dinner", amount: 100, createdById: "bob", splits: [],
    });
    await setDoc(doc(db, "groups/g1/settlements/s1"), {
      amount: 10, createdById: "bob",
    });
    await setDoc(doc(db, "users/alice"), { name: "Alice", email: "a@x.com" });
    await setDoc(doc(db, "users/alice/private/push"), { fcmToken: "tok" });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

// ── groups: read ────────────────────────────────────────────────────────────
test("members can read their group; outsiders and anonymous cannot", async () => {
  await assertSucceeds(getDoc(doc(as("bob"), "groups/g1")));
  await assertFails(getDoc(doc(as("carol"), "groups/g1")));
  await assertFails(getDoc(doc(anon(), "groups/g1")));
});

test("the watchUserGroups query (memberIds array-contains) works for the owner only", async () => {
  const q = (uid) =>
    query(collection(as(uid), "groups"), where("memberIds", "array-contains", uid));
  await assertSucceeds(getDocs(q("bob")));
  // an outsider listing everything is refused
  await assertFails(getDocs(collection(as("carol"), "groups")));
});

// ── groups: create ──────────────────────────────────────────────────────────
test("create: must be sole member and creator", async () => {
  const db = as("carol");
  await assertSucceeds(setDoc(doc(db, "groups/new"), {
    name: "X", createdBy: "carol", memberIds: ["carol"], adminIds: ["carol"],
  }));
  await assertFails(setDoc(doc(db, "groups/new2"), {
    name: "X", createdBy: "alice", memberIds: ["carol"],
  }));
  await assertFails(setDoc(doc(db, "groups/new3"), {
    name: "X", createdBy: "carol", memberIds: ["carol", "alice"],
  }));
  await assertFails(setDoc(doc(db, "groups/new4"), {
    name: "X", createdBy: "carol", memberIds: ["carol"], adminIds: ["alice"],
  }));
});

// ── groups: update ──────────────────────────────────────────────────────────
test("admin can edit details, remove members, and manage admins", async () => {
  const db = as("alice");
  await assertSucceeds(updateDoc(doc(db, "groups/g1"), { name: "Renamed" }));
  await assertSucceeds(updateDoc(doc(db, "groups/g1"), { inviteCode: "ZZZZ9999" }));
  await assertSucceeds(updateDoc(doc(db, "groups/g1"), { adminIds: ["alice", "bob"] }));
  // removing an admin must also drop them from adminIds
  await assertFails(updateDoc(doc(db, "groups/g1"), {
    memberIds: ["alice"], memberNames: { alice: "Alice" },
  }));
  await assertSucceeds(updateDoc(doc(db, "groups/g1"), {
    memberIds: ["alice"], memberNames: { alice: "Alice" }, adminIds: ["alice"],
  }));
});

test("legacy group (no adminIds): creator still counts as admin", async () => {
  await assertSucceeds(updateDoc(doc(as("alice"), "groups/legacy"), { name: "New" }));
  await assertFails(updateDoc(doc(as("bob"), "groups/legacy"), { name: "Hax" }));
});

test("non-admin members cannot rename, change admins, or reset the invite code", async () => {
  const db = as("bob");
  await assertFails(updateDoc(doc(db, "groups/g1"), { name: "Hax" }));
  await assertFails(updateDoc(doc(db, "groups/g1"), { adminIds: ["alice", "bob"] }));
  await assertFails(updateDoc(doc(db, "groups/g1"), { inviteCode: "STOLEN12" }));
  await assertFails(updateDoc(doc(db, "groups/g1"), { createdBy: "bob" }));
});

test("non-admin member can touch updatedAt and add members, but not remove others", async () => {
  const db = as("bob");
  await assertSucceeds(updateDoc(doc(db, "groups/g1"), { updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(db, "groups/g1"), {
    memberIds: arrayUnion("dave"), "memberNames.dave": "Dave",
  }));
  await assertFails(updateDoc(doc(db, "groups/g1"), {
    memberIds: ["bob"], memberNames: { bob: "Bob" },
  }));
});

test("a member can leave on their own, but not take someone else out", async () => {
  await assertSucceeds(updateDoc(doc(as("bob"), "groups/g1"), {
    memberIds: ["alice"], memberNames: { alice: "Alice" },
  }));
});

test("a leaving admin must drop their own admin role in the same write", async () => {
  await env.withSecurityRulesDisabled((ctx) =>
    updateDoc(doc(ctx.firestore(), "groups/g1"), { adminIds: ["alice", "bob"] }));
  const db = as("bob");
  await assertFails(updateDoc(doc(db, "groups/g1"), {
    memberIds: ["alice"], memberNames: { alice: "Alice" },
  }));
  await assertSucceeds(updateDoc(doc(db, "groups/g1"), {
    memberIds: ["alice"], memberNames: { alice: "Alice" }, adminIds: ["alice"],
  }));
});

test("outsiders cannot join by writing themselves in", async () => {
  await assertFails(updateDoc(doc(as("carol"), "groups/g1"), {
    memberIds: arrayUnion("carol"), "memberNames.carol": "Carol",
  }));
});

// ── groups: delete ──────────────────────────────────────────────────────────
test("only an admin can delete a group", async () => {
  await assertFails(deleteDoc(doc(as("bob"), "groups/g1")));
  await assertFails(deleteDoc(doc(as("carol"), "groups/g1")));
  await assertSucceeds(deleteDoc(doc(as("alice"), "groups/g1")));
});

// ── expenses ────────────────────────────────────────────────────────────────
test("expenses: members read/write, outsiders locked out", async () => {
  await assertSucceeds(getDoc(doc(as("bob"), "groups/g1/expenses/e1")));
  await assertSucceeds(getDocs(collection(as("bob"), "groups/g1/expenses")));
  await assertFails(getDoc(doc(as("carol"), "groups/g1/expenses/e1")));
  await assertFails(getDocs(collection(as("carol"), "groups/g1/expenses")));

  await assertSucceeds(addDoc(collection(as("alice"), "groups/g1/expenses"), {
    title: "Taxi", createdById: "alice",
  }));
  // cannot impersonate another creator
  await assertFails(addDoc(collection(as("alice"), "groups/g1/expenses"), {
    title: "Taxi", createdById: "bob",
  }));
  await assertFails(addDoc(collection(as("carol"), "groups/g1/expenses"), {
    title: "Taxi", createdById: "carol",
  }));
});

test("expense edit keeps the original author; any member may edit or delete", async () => {
  await assertSucceeds(updateDoc(doc(as("alice"), "groups/g1/expenses/e1"), {
    title: "Dinner out", updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(as("alice"), "groups/g1/expenses/e1"), {
    createdById: "alice",
  }));
  await assertFails(updateDoc(doc(as("carol"), "groups/g1/expenses/e1"), { title: "x" }));
  await assertSucceeds(deleteDoc(doc(as("alice"), "groups/g1/expenses/e1")));
});

// ── settlements ─────────────────────────────────────────────────────────────
test("settlements: members create, nobody edits or deletes", async () => {
  await assertSucceeds(getDoc(doc(as("alice"), "groups/g1/settlements/s1")));
  await assertSucceeds(setDoc(doc(as("alice"), "groups/g1/settlements/s2"), {
    amount: 5, createdById: "alice",
  }));
  await assertFails(setDoc(doc(as("alice"), "groups/g1/settlements/s3"), {
    amount: 5, createdById: "bob",
  }));
  await assertFails(setDoc(doc(as("carol"), "groups/g1/settlements/s4"), {
    amount: 5, createdById: "carol",
  }));
  await assertFails(updateDoc(doc(as("bob"), "groups/g1/settlements/s1"), { amount: 1 }));
  await assertFails(deleteDoc(doc(as("bob"), "groups/g1/settlements/s1")));
  await assertFails(getDoc(doc(as("carol"), "groups/g1/settlements/s1")));
});

// ── users ───────────────────────────────────────────────────────────────────
test("users: any signed-in user can read profiles, only the owner can write", async () => {
  await assertSucceeds(getDoc(doc(as("bob"), "users/alice")));
  await assertFails(getDoc(doc(anon(), "users/alice")));
  await assertSucceeds(updateDoc(doc(as("alice"), "users/alice"), { name: "Al" }));
  await assertFails(updateDoc(doc(as("bob"), "users/alice"), { name: "Hax" }));
});

test("push tokens are private to their owner", async () => {
  await assertSucceeds(getDoc(doc(as("alice"), "users/alice/private/push")));
  await assertSucceeds(setDoc(doc(as("alice"), "users/alice/private/push"), { fcmToken: "t2" }));
  await assertFails(getDoc(doc(as("bob"), "users/alice/private/push")));
  await assertFails(setDoc(doc(as("bob"), "users/alice/private/push"), { fcmToken: "evil" }));
});

test("notifications: others can deliver, only owner reads; sender cannot be forged", async () => {
  const n = (actorId) => ({ type: "expense_added", title: "t", body: "b", actorId, isRead: false });
  await assertSucceeds(addDoc(collection(as("bob"), "users/alice/notifications"), n("bob")));
  await assertFails(addDoc(collection(as("bob"), "users/alice/notifications"), n("carol")));
  await assertFails(addDoc(collection(anon(), "users/alice/notifications"), n("bob")));

  await assertSucceeds(getDocs(collection(as("alice"), "users/alice/notifications")));
  await assertFails(getDocs(collection(as("bob"), "users/alice/notifications")));
});

test("admins can't promote someone who isn't a member", async () => {
  await assertFails(updateDoc(doc(as("alice"), "groups/g1"), { adminIds: ["alice", "carol"] }));
});
