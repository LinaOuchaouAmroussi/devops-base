import streamlit as st
import requests

st.title("Test Trend Tracker")

# On essaie de contacter le backend (nom du service dans docker-compose)
try:
    response = requests.get("http://backend:8000/health")
    if response.status_code == 200:
        st.success(f"Connecté au Backend ! Réponse : {response.json()}")
    else:
        st.error("Backend joignable mais erreur serveur.")
except Exception as e:
    st.warning(f"En attente du backend... ({e})")

st.write("Si tu vois 'connected', ton architecture Docker est validée !")