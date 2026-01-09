"""
Waste Classification Utility using Google Gemini AI - Exact copy of working web implementation
"""
import os
import json
import base64
from google import genai
from dotenv import load_dotenv

load_dotenv()


def classify_waste_image(image_file):
    """
    Classify waste from an uploaded image file using the exact same logic as web version
    
    Args:
        image_file: Django UploadedFile object
        
    Returns:
        dict: Classification results with waste_category, materials_detected, confidence
    """
    try:
        # Check API key first
        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            print("No API key found")
            return {
                "error": "GEMINI_API_KEY not configured in .env file",
                "waste_category": "single",
                "materials_detected": [{"material": "unknown", "recyclable": False}],
                "confidence": 0
            }
        
        # Initialize client (same as web version)
        client = genai.Client(api_key=api_key)
        
        # Read image bytes
        image_file.seek(0)
        image_bytes = image_file.read()
        
        # Use exact same model and prompt as web version
        MODEL_NAME = "models/gemini-2.5-flash"
        
        prompt = """
You are an expert waste and recycling classification AI used in India.

CRITICAL RULES FOR FAKE DETECTION:
1. If this image shows people, faces, landscapes, food, animals, or non-waste objects - set confidence to 0
2. If this is a screenshot, meme, text image, or digitally generated content - set confidence to 0
3. If this shows clean/new products that are NOT discarded waste - set confidence to 0
4. ONLY classify actual discarded waste materials that need disposal/recycling

Your task:
1. Identify ALL visible waste items in the image.
2. Classify each item into a specific material category.
3. Estimate realistic weight for each material based on visible size.
4. If the image contains multiple items, treat it as mixed waste.

Use ONLY these material categories with weight guidelines:
- iron: 0.5-5kg (scraps, tools, parts)
- steel: 0.2-3kg (cans, containers, sheets)
- aluminum: 0.02-0.5kg (cans, foil, small items)
- copper: 0.1-1kg (wires, pipes, fittings)
- plastic_pet: 0.01-0.05kg (bottles, containers)
- plastic_other: 0.05-2kg (bags, packaging, large items)
- paper: 0.1-1kg (documents, newspapers, packaging)
- cardboard: 0.2-2kg (boxes, packaging)
- glass: 0.1-1kg (bottles, jars, broken glass)
- organic: 0.5-3kg (food waste, garden waste)
- electronic: 0.2-5kg (phones, components, small devices)
- unknown: 0.1-0.5kg (unidentifiable waste)

Weight estimation rules:
- Small bottle/can: 0.02-0.05kg
- Medium container/bag: 0.2-0.5kg
- Large box/appliance: 1-5kg
- Be realistic based on typical waste sizes

Rules:
- Do NOT use generic terms like "metal waste" or "scrap waste".
- Always name the specific material.
- If more than one material is present, list all of them with individual weights.
- Confidence should reflect overall certainty about waste classification.
- For fake/non-waste images, always set confidence to 0.

Respond ONLY in valid JSON using this exact format:

{
  "waste_category": "single | mixed",
  "materials_detected": [
    {
      "material": "string",
      "recyclable": true/false,
      "estimated_weight_kg": number
    }
  ],
  "confidence": number (0-100)
}

"""

        # Call Gemini API with exact same structure as web version
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
        
        # Parse response exactly like web version
        text = response.text.strip()
        print(f"Gemini Response: {text}")
        
        if text.startswith("```"):
            text = text.replace("```json", "").replace("```", "").strip()
        
        result = json.loads(text)
        
        # Enhanced fake detection
        confidence = result.get("confidence", 0)
        materials = result.get("materials_detected", [])
        
        # If AI detected fake/non-waste content
        if confidence == 0 or confidence < 5:
            return {
                "waste_category": "fake",
                "materials_detected": [],
                "confidence": 0,
                "error": "❌ Fake or invalid image detected! Please upload a clear photo of actual waste materials only. Do not upload photos of people, food, landscapes, or clean products."
            }
        
        # Validate materials have weights
        for material in materials:
            if 'estimated_weight_kg' not in material:
                material['estimated_weight_kg'] = 0.3  # Default weight
            
            # Ensure weight is reasonable
            weight = material['estimated_weight_kg']
            if weight <= 0 or weight > 10:
                material['estimated_weight_kg'] = 0.3
        
        # Calculate total weight
        total_weight = sum(m.get('estimated_weight_kg', 0) for m in materials)
        result['total_estimated_weight_kg'] = round(total_weight, 2)
        
        # Return the genuine result from Gemini
        return result
        
    except json.JSONDecodeError as e:
        print(f"JSON Parse Error: {e}")
        return {
            "waste_category": "single",
            "materials_detected": [{"material": "unknown", "recyclable": False}],
            "confidence": 0,
            "error": "Failed to parse AI response"
        }
        
    except Exception as e:
        print(f"Classification Error: {e}")
        return {
            "waste_category": "single",
            "materials_detected": [{"material": "unknown", "recyclable": False}],
            "confidence": 0,
            "error": f"Classification failed: {str(e)}"
        }
