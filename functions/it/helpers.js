"use strict";
// Emulator-backed helpers. Run via `npm run test:it` (see package.json).

const admin = require("firebase-admin");

const PROJECT = process.env.GCLOUD_PROJECT || "demo-paypact";
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const fnHost = process.env.FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";

async function signUp(email, name) {
  const res = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email, password: "pass1234", displayName: name, returnSecureToken: true }),
    }
  );
  const j = await res.json();
  if (!j.idToken) throw new Error("signUp failed: " + JSON.stringify(j));
  await db.doc(`users/${j.localId}`).set({ name, email: email.toLowerCase() });
  return { uid: j.localId, token: j.idToken, name };
}

/** Calls an HTTPS callable the way the client SDK does. */
async function call(name, data, token) {
  const res = await fetch(`http://${fnHost}/${PROJECT}/us-central1/${name}`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ data }),
  });
  const body = await res.json();
  return { status: res.status, result: body.result, error: body.error };
}

/** Polls until fn() returns a truthy value (triggers are asynchronous). */
async function eventually(fn, { timeout = 15000, interval = 250, what = "condition" } = {}) {
  const start = Date.now();
  let last;
  while (Date.now() - start < timeout) {
    last = await fn();
    if (last) return last;
    await new Promise((r) => setTimeout(r, interval));
  }
  throw new Error(`Timed out waiting for ${what}`);
}

async function makeGroup(id, { admin: adminId, members, currency = "INR", extra = {} }) {
  await db.doc(`groups/${id}`).set({
    name: `Group ${id}`,
    emoji: "🏖",
    category: "trip",
    currency,
    createdBy: adminId,
    adminIds: [adminId],
    memberIds: members.map((m) => m.uid),
    memberNames: Object.fromEntries(members.map((m) => [m.uid, m.name])),
    createdAt: require("firebase-admin/firestore").FieldValue.serverTimestamp(),
    ...extra,
  });
  return db.doc(`groups/${id}`);
}

const uniq = () => Math.random().toString(36).slice(2, 8);

module.exports = { admin, db, signUp, call, eventually, makeGroup, uniq, PROJECT };
