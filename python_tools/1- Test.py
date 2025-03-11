# script1.py
import os

print("Esecuzione dello script Python: Creazione di una cartella di test")
try:
    os.makedirs("C:\\TestFolder", exist_ok=True)
    print("Cartella creata con successo!")
except Exception as e:
    print(f"Errore: {e}")