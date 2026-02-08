// Simple Firestore seeder for recipes using a JSON file.
// Usage:
// 1) Place your Firebase Admin SDK service account key at the project root as serviceAccountKey.json
//    or set SERVICE_ACCOUNT_KEY=full_path_to_key.json in your environment.
// 2) Put recipes in seeds/recipes_seed.json (see sample file).
// 3) Run: npm install firebase-admin
// 4) Run: node scripts/seed_recipes.js

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const keyPath =
  process.env.SERVICE_ACCOUNT_KEY ||
  path.join(__dirname, "..", "serviceAccountKey.json");
const seedPath = path.join(__dirname, "..", "seeds", "recipes_seed.json");

if (!fs.existsSync(keyPath)) {
  console.error(
    "Missing service account key. Provide serviceAccountKey.json or set SERVICE_ACCOUNT_KEY."
  );
  process.exit(1);
}

if (!fs.existsSync(seedPath)) {
  console.error("Missing seed file at seeds/recipes_seed.json");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(keyPath)),
});

const db = admin.firestore();

function loadSeeds() {
  const raw = fs.readFileSync(seedPath, "utf8");
  const data = JSON.parse(raw);
  if (!Array.isArray(data)) throw new Error("Seed file must be a JSON array");
  return data;
}

(async () => {
  try {
    const recipes = loadSeeds();
    if (recipes.length === 0) {
      console.log("No recipes to seed.");
      process.exit(0);
    }

    const batch = db.batch();
    recipes.forEach((recipe) => {
      const docRef = db.collection("recipes").doc();
      batch.set(docRef, {
        ...recipe,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        likes: recipe.likes ?? 0,
        approved: recipe.approved ?? true,
      });
    });

    await batch.commit();
    console.log(`Seeded ${recipes.length} recipes.`);
    process.exit(0);
  } catch (err) {
    console.error("Seed failed:", err.message);
    process.exit(1);
  }
})();
