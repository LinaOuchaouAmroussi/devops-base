from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    """Vérifie que l'API est en ligne."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "online", "database": "connected"}

def test_sentiment_analysis():
    """Vérifie que l'IA distingue le positif du négatif."""
    # Test Positif
    res_pos = client.post("/analyze", json={"content": "I love this product, it is amazing!"})
    assert res_pos.status_code == 200
    assert res_pos.json()["sentiment"] == "POSITIVE"

    # Test Négatif
    res_neg = client.post("/analyze", json={"content": "This is a terrible experience, I hate it."})
    assert res_neg.status_code == 200
    assert res_neg.json()["sentiment"] == "NEGATIVE"