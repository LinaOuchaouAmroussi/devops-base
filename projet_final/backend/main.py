from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import pipeline
from motor.motor_asyncio import AsyncIOMotorClient
import datetime
import os

# --- CONFIGURATION IA ---
# On charge un modèle de NLP (Natural Language Processing) spécialisé dans les sentiments
print("Chargement du modèle DistilBERT...")
nlp_pipeline = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")

# --- CONFIGURATION BASE DE DONNÉES ---
# L'URL changera selon l'environnement (Local vs Cloud)
MONGO_URL = os.getenv("DATABASE_URL", "mongodb://localhost:27017")
client = AsyncIOMotorClient(MONGO_URL)
db = client.trend_db
collection = db.analyses

app = FastAPI(title="Trend Tracker API")

# Modèle de données pour valider l'entrée utilisateur
class TextInput(BaseModel):
    content: str

# --- ROUTES API ---

@app.post("/analyze")
async def analyze_sentiment(input_data: TextInput):
    """Analyse le texte, l'enregistre en base et renvoie le résultat."""
    try:
        # 1. Analyse par l'IA
        result = nlp_pipeline(input_data.content)[0]
        
        # 2. Création du document (Data Engineering)
        document = {
            "text": input_data.content,
            "label": result['label'],
            "score": round(result['score'], 4),
            "created_at": datetime.datetime.utcnow()
        }
        
        # 3. Insertion dans MongoDB
        new_doc = await collection.insert_one(document)
        
        return {
            "id": str(new_doc.inserted_id),
            "sentiment": result['label'],
            "confidence": result['score']
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur IA/DB: {str(e)}")

@app.get("/history")
async def get_history():
    """Récupère les 10 dernières analyses stockées (Aspect CRUD)."""
    cursor = collection.find().sort("created_at", -1).limit(10)
    history = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        history.append(doc)
    return history

@app.get("/health")
async def health():
    """Route de santé pour Kubernetes (Liveness Probe)."""
    return {"status": "online", "database": "connected"}