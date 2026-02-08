// Copy recipes from 'recipes' collection to 'featured_recipes' collection.
// Usage: node scripts/copy_to_featured.js <recipeId1> <recipeId2> ...
// Example: node scripts/copy_to_featured.js abc123 def456

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const keyPath =
  process.env.SERVICE_ACCOUNT_KEY ||
  path.join(__dirname, "..", "serviceAccountKey.json");

if (!fs.existsSync(keyPath)) {
  console.error(
    "Missing service account key. Provide serviceAccountKey.json or set SERVICE_ACCOUNT_KEY."
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(keyPath)),
});

const db = admin.firestore();

const recipeIds = process.argv.slice(2);

if (recipeIds.length === 0) {
  console.error(
    "Usage: node scripts/copy_to_featured.js <recipeId1> <recipeId2> ..."
  );
  console.error("Example: node scripts/copy_to_featured.js abc123 def456");
  process.exit(1);
}

(async () => {
  try {
    let copied = 0;
    let skipped = 0;

    for (const recipeId of recipeIds) {
      const recipeDoc = await db.collection("recipes").doc(recipeId).get();

      if (!recipeDoc.exists) {
        console.warn(
          `Recipe ${recipeId} not found in recipes collection. Skipping.`
        );
        skipped++;
        continue;
      }

      const recipeData = recipeDoc.data();

      // Copy to featured_recipes with the same ID (or use .doc() without arg for new ID)
      await db.collection("featured_recipes").doc(recipeId).set(recipeData);

      console.log(`Copied recipe: ${recipeData.name} (${recipeId})`);
      copied++;
    }

    console.log(`\nDone! Copied ${copied} recipe(s), skipped ${skipped}.`);
    process.exit(0);
  } catch (err) {
    console.error("Copy failed:", err.message);
    process.exit(1);
  }
})();
