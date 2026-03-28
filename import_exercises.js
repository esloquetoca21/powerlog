#!/usr/bin/env node
/**
 * import_exercises.js
 *
 * Imports powerlog_exercises_v4_DEFINITIVA.json into the Firestore
 * 'exercises' collection using Firebase Admin SDK with batch writes
 * (max 500 operations per batch).
 *
 * Usage:
 *   node import_exercises.js
 *
 * Requirements:
 *   npm install firebase-admin
 *
 * Files expected in the same directory as this script:
 *   - serviceAccountKey.json   (Firebase service account credentials)
 *   - powerlog_exercises_v4_DEFINITIVA.json  (array of exercise objects)
 */

const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');

// ── Load credentials ──────────────────────────────────────────────────────────

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌  serviceAccountKey.json not found in project root.');
  process.exit(1);
}

const exercisesPath = path.join(__dirname, 'powerlog_exercises_v4_DEFINITIVA.json');
if (!fs.existsSync(exercisesPath)) {
  console.error('❌  powerlog_exercises_v4_DEFINITIVA.json not found in project root.');
  process.exit(1);
}

// ── Init Firebase Admin ───────────────────────────────────────────────────────

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Load exercises ─────────────────────────────────────────────────────────────

const raw = fs.readFileSync(exercisesPath, 'utf8');
let exercises;
try {
  exercises = JSON.parse(raw);
} catch (err) {
  console.error('❌  Failed to parse JSON:', err.message);
  process.exit(1);
}

if (!Array.isArray(exercises)) {
  console.error('❌  JSON root must be an array of exercise objects.');
  process.exit(1);
}

console.log(`📦  Found ${exercises.length} exercises to import.`);

// ── Batch import ───────────────────────────────────────────────────────────────

const BATCH_SIZE = 500;
const collection = db.collection('exercises');

async function importAll() {
  let imported = 0;
  let batchNumber = 0;

  for (let i = 0; i < exercises.length; i += BATCH_SIZE) {
    const chunk = exercises.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    batchNumber++;

    for (const exercise of chunk) {
      // Use exercise.id as document ID if present, otherwise auto-generate.
      const docRef = exercise.id
        ? collection.doc(String(exercise.id))
        : collection.doc();

      // Ensure every document has a timestamp field (project convention).
      const data = {
        ...exercise,
        timestamp: exercise.timestamp ?? new Date().toISOString(),
      };

      batch.set(docRef, data);
    }

    await batch.commit();
    imported += chunk.length;
    console.log(`  ✅  Batch ${batchNumber}: committed ${chunk.length} docs (total ${imported}/${exercises.length})`);
  }

  console.log(`\n🎉  Import complete. ${imported} exercises written to 'exercises' collection.`);
}

importAll().catch((err) => {
  console.error('❌  Import failed:', err);
  process.exit(1);
});
