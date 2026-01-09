import os
import json
import requests
from google import genai
from dotenv import load_dotenv


load_dotenv()

client = genai.Client(
    api_key=os.environ.get("GEMINI_API_KEY"),
)


IMAGE_URL = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ8FB5s9zuEDsXRxBfitCIagRkLHXaDvTmQEQ&s"

resp = requests.get(IMAGE_URL, timeout=20, headers={"User-Agent": "Mozilla/5.0"}, allow_redirects=True)
resp.raise_for_status()
image_bytes = resp.content

MODEL_NAME = "models/gemini-2.5-flash"

prompt = """
You are an expert waste and recycling classification AI used in India.

Your task:
1. Identify ALL visible waste items in the image.
2. Classify each item into a specific material category.
3. If the image contains multiple items, treat it as mixed waste.

Use ONLY these material categories:
- iron
- steel
- aluminum
- copper
- plastic_pet
- plastic_other
- paper
- cardboard
- glass
- organic
- electronic
- unknown

Rules:
- Do NOT use generic terms like "metal waste" or "scrap waste".
- Always name the specific material.
- If more than one material is present, list all of them.
- Confidence should reflect overall certainty.

Respond ONLY in valid JSON using this exact format:

{
  "waste_category": "single | mixed",
  "materials_detected": [
    {
      "material": "string",
      "recyclable": true/false
    }
  ],
  "confidence": number (0-100)
}

"""


response = client.models.generate_content(
    model=MODEL_NAME,
    contents=[
        {
            "role": "user",
            "parts": [
                {"text": prompt},
                {"inline_data": {"mime_type": "image/jpeg", "data": image_bytes}},
            ],
        }
    ],
)


text = response.text.strip()
if text.startswith("```"):
    text = text.replace("```json", "").replace("```", "").strip()


result = json.loads(text)

print("Gemini Response:")
print(json.dumps(result, indent=2))