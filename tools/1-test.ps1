# Definisci il percorso della cartella da creare
$folderPath = "C:\TestFolder"

# Verifica se la cartella esiste già
if (-Not (Test-Path -Path $folderPath)) {
    try {
        # Crea la cartella
        New-Item -Path $folderPath -ItemType Directory -ErrorAction Stop
        Write-Host "La cartella '$folderPath' è stata creata con successo." -ForegroundColor Green
    } catch {
        # Gestisci eventuali errori durante la creazione della cartella
        Write-Host "Si è verificato un errore durante la creazione della cartella: $_" -ForegroundColor Red
    }
} else {
    # Se la cartella esiste già, mostra un messaggio
    Write-Host "La cartella '$folderPath' esiste già." -ForegroundColor Yellow
}