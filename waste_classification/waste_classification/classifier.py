import os
import json
import requests
import google.generativeai as genai
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure Gemini (NO client object)
genai.configure(
    api_key=os.environ.get("GEMINI_API_KEY")
)

# Download image
IMAGE_URL = "https://media.gettyimages.com/id/1138822598/photo/rubbish-in-bin-unsorted.jpg?s=612x612&w=gi&k=20&c=UghVMS01N3BpPO3mrzj3vDNKu9cUUK5MQZQbRa8b4GE="
resp = requests.get(
    IMAGE_URL,
    timeout=20,
    headers={"User-Agent": "Mozilla/5.0"},
)
resp.raise_for_status()

image_bytes = resp.content

# Gemini model (Python SDK format)
MODEL_NAME = "gemini-2.5-flash"

model = genai.GenerativeModel(MODEL_NAME)

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

# Generate response with image
response = model.generate_content(
    [
        prompt,
        {
            "mime_type": "image/jpeg",
            "data": image_bytes,
        },
    ]
)

# Clean response
text = response.text.strip()

if text.startswith("```"):
    text = text.replace("```json", "").replace("```", "").strip()

# Parse JSON safely
result = json.loads(text)

print("Gemini Response:")
print(json.dumps(result, indent=2))
