Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configurazione
$repoUrl = "https://raw.githubusercontent.com/tuonome/repository/main/"
$pythonVersion = "3.12.3"
$pythonEmbeddableUrl = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-embed-amd64.zip"
$pythonDir = "$env:TEMP\python_embeddable"
$toolsDir = "$repoUrl/tools"
$pythonToolsDir = "$repoUrl/python_tools"

# Variabili globali
$pythonInstalled = $false
$pythonPath = $null

# Creazione GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Tool Manager"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

# Label di stato
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 20)
$statusLabel.Size = New-Object System.Drawing.Size(560, 20)
$statusLabel.Text = "Verifica Python..."
$form.Controls.Add($statusLabel)

# TreeView per i tool
$tree = New-Object System.Windows.Forms.TreeView
$tree.Location = New-Object System.Drawing.Point(10, 50)
$tree.Size = New-Object System.Drawing.Size(560, 250)
$form.Controls.Add($tree)

# Pulsante Esegui
$executeButton = New-Object System.Windows.Forms.Button
$executeButton.Location = New-Object System.Drawing.Point(450, 320)
$executeButton.Size = New-Object System.Drawing.Size(120, 30)
$executeButton.Text = "Esegui"
$executeButton.Enabled = $false
$form.Controls.Add($executeButton)

# Funzione per aggiornare lo stato
function Update-Status {
    param ([string]$message)
    $statusLabel.Text = $message
    $statusLabel.Update()
}

# Verifica Python
function Check-Python {
    Update-Status "Verifica Python..."
    $pythonExe = Get-Command python -ErrorAction SilentlyContinue

    if ($pythonExe) {
        $script:pythonInstalled = $true
        $script:pythonPath = $pythonExe.Source
        Update-Status "Python trovato: $($pythonExe.Source)"
    } else {
        Update-Status "Python non trovato. Vuoi installare Python Embeddable?"
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Python non è installato. Installare Python Embeddable per continuare?",
            "Python Mancante",
            [System.Windows.Forms.MessageBoxButtons]::YesNo
        )
        if ($result -eq "Yes") {
            Install-PythonEmbeddable
        } else {
            Update-Status "Python non disponibile. Alcuni tool potrebbero non funzionare."
        }
    }
}

# Installa Python Embeddable
function Install-PythonEmbeddable {
    try {
        Update-Status "Installazione Python Embeddable..."
        if (-not (Test-Path $pythonDir)) {
            New-Item -ItemType Directory -Path $pythonDir | Out-Null
        }

        $zipPath = "$env:TEMP\python_embeddable.zip"
        Invoke-WebRequest -Uri $pythonEmbeddableUrl -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $pythonDir -Force
        Remove-Item $zipPath -Force

        $script:pythonPath = "$pythonDir\python.exe"
        $script:pythonInstalled = $true
        Update-Status "Python Embeddable installato in: $pythonDir"
    } catch {
        Update-Status "Errore durante l'installazione di Python Embeddable: $_"
    }
}

# Popola TreeView con i tool
function Load-Tools {
    $tree.Nodes.Clear()

    # Aggiungi cartelle PowerShell
    $psNode = New-Object System.Windows.Forms.TreeNode("PowerShell Tools")
    $psNode.Tag = "folder"
    $tree.Nodes.Add($psNode)

    # Aggiungi cartelle Python
    $pyNode = New-Object System.Windows.Forms.TreeNode("Python Tools")
    $pyNode.Tag = "folder"
    $tree.Nodes.Add($pyNode)

    # Simula il caricamento dei tool (da sostituire con chiamate reali al repository)
    # Esempio statico (sostituire con logica dinamica)
    $psScripts = @("script1.ps1", "script2.ps1")
    $pyScripts = @("script1.py", "script2.py")

    foreach ($script in $psScripts) {
        $child = New-Object System.Windows.Forms.TreeNode($script)
        $child.Tag = "ps1"
        $psNode.Nodes.Add($child)
    }

    foreach ($script in $pyScripts) {
        $child = New-Object System.Windows.Forms.TreeNode($script)
        $child.Tag = "py"
        $pyNode.Nodes.Add($child)
    }

    $tree.ExpandAll()
    $executeButton.Enabled = $true
}

# Esegui il tool selezionato
$executeButton.Add_Click({
    $selectedNode = $tree.SelectedNode
    if (-not $selectedNode -or $selectedNode.Tag -eq "folder") {
        [System.Windows.Forms.MessageBox]::Show("Seleziona uno script valido.")
        return
    }

    $scriptType = $selectedNode.Tag
    $scriptName = $selectedNode.Text

    try {
        if ($scriptType -eq "ps1") {
            $scriptUrl = "$toolsDir/$scriptName"
            Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing | Invoke-Expression
        } elseif ($scriptType -eq "py") {
            if (-not $pythonInstalled) {
                throw "Python non disponibile"
            }
            $scriptUrl = "$pythonToolsDir/$scriptName"
            $tempScript = "$env:TEMP\$scriptName"
            Invoke-WebRequest -Uri $scriptUrl -OutFile $tempScript -UseBasicParsing
            & $pythonPath $tempScript
            Remove-Item $tempScript -Force
        }
        [System.Windows.Forms.MessageBox]::Show("Esecuzione completata!")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Errore durante l'esecuzione: $_")
    }
})

# Avvio
Check-Python
Load-Tools
[void]$form.ShowDialog()