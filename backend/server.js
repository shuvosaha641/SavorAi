import express from "express";
import Groq from "groq-sdk";
import cors from "cors";

const app = express();
app.use(cors());
app.use(express.json());

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

app.get("/", (req, res) => {
  res.json({ status: "SavorAI Backend Running" });
});

app.post("/generate-recipe", async (req, res) => {
  const { ingredients } = req.body;

  if (!ingredients) {
    return res.status(400).json({ error: "Ingredients required" });
  }

  try {
    const completion = await groq.chat.completions.create({
      model: "llama-3.1-8b-instant",
      messages: [
        {
          role: "user",
          content: `Generate a detailed recipe using ONLY these ingredients: ${ingredients}

Respond ONLY with valid JSON in this exact format, no extra text before or after:
{
  "name": "Recipe Name",
  "description": "Brief one-line description",
  "ingredients": "Ingredient 1\\nIngredient 2\\nIngredient 3",
  "instructions": "Step 1. Description\\nStep 2. Description\\nStep 3. Description",
  "cookingTime": 30,
  "servings": 4,
  "category": "Main",
  "tips": "Helpful cooking tips"
}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 800,
    });

    const content = completion.choices[0].message.content;
    console.log("Raw response:", content);

    const recipe = JSON.parse(content);
    res.json(recipe);
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🚀 SavorAI Backend running on port ${PORT}`);
  console.log(
    `🔑 API Key configured: ${process.env.GROQ_API_KEY ? "Yes" : "No"}`
  );
});
