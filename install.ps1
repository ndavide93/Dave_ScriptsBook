Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configurazione
$repoOwner = "ndavide93"
$repoName = "Dave_ScriptsBook"
$repoUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main/"
$pythonEmbeddableZip = "$repoUrl/python_embeddable/python-3.13.2-embed-amd64.zip"
$pythonDir = "$env:TEMP\python_embeddable"

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
$statusLabel.Text = "Caricamento..."
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

# Installa Python Embeddable
function Install-PythonEmbeddable {
    try {
        Update-Status "Installazione Python Embeddable..."

        if (-not (Test-Path $pythonDir)) {
            New-Item -ItemType Directory -Path $pythonDir | Out-Null
        }

        $zipPath = "$env:TEMP\python_embeddable.zip"
        Invoke-WebRequest -Uri $pythonEmbeddableZip -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $pythonDir -Force
        Remove-Item $zipPath -Force

        $script:pythonPath = "$pythonDir\python.exe"
        if (-not (Test-Path $pythonPath)) {
            throw "python.exe non trovato nello zip."
        }

        $env:PATH = "$pythonDir;$env:PATH"
        $script:pythonInstalled = $true
        Update-Status "Python Embeddable installato in: $pythonDir"
    } catch {
        Update-Status "Errore durante l'installazione di Python Embeddable: $_"
    }
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
        Update-Status "Python non trovato. Installazione di Python Embeddable..."
        Install-PythonEmbeddable
    }
}

# Ottieni la lista dei file da GitHub
function Get-GitHubFiles {
    param (
        [string]$folderPath
    )
    $url = "https://api.github.com/repos/$repoOwner/$repoName/contents/$folderPath"
    try {
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Headers @{ "Accept" = "application/vnd.github.v3+json" }
        return $response | Where-Object { $_.type -eq "file" } | ForEach-Object { $_.name }
    } catch {
        Write-Host "Errore nel recupero dei file da GitHub: $_"
        return @()
    }
}

# Popola TreeView con i tool
function Load-Tools {
    $tree.Nodes.Clear()

    $psNode = New-Object System.Windows.Forms.TreeNode("PowerShell Tools")
    $psNode.Tag = "folder"
    $tree.Nodes.Add($psNode)

    $pyNode = New-Object System.Windows.Forms.TreeNode("Python Tools")
    $pyNode.Tag = "folder"
    $tree.Nodes.Add($pyNode)

    $psScripts = Get-GitHubFiles -folderPath "tools"  # Aggiorna se necessario
    foreach ($script in $psScripts) {
        $child = New-Object System.Windows.Forms.TreeNode($script)
        $child.Tag = "ps1"
        $psNode.Nodes.Add($child)
    }

    $pyScripts = Get-GitHubFiles -folderPath "python_tools"  # Aggiorna se necessario
    foreach ($script in $pyScripts) {
        $child = New-Object System.Windows.Forms.TreeNode($script)
        $child.Tag = "py"
        $pyNode.Nodes.Add($child)
    }

    $tree.ExpandAll()
    $executeButton.Enabled = $true
    Update-Status "Caricamento completato."
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
            $scriptUrl = "$repoUrl/tools/$scriptName"  # Aggiorna se necessario
            Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing | Invoke-Expression
        } elseif ($scriptType -eq "py") {
            if (-not $pythonInstalled) {
                throw "Python non disponibile"
            }

            $appExecutionAlias = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\python.exe" -ErrorAction SilentlyContinue
            if ($appExecutionAlias) {
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\python.exe" -Name "(Default)" -Value ""
            }

            $scriptUrl = "$repoUrl/python_tools/$scriptName"  # Aggiorna se necessario
            $tempScript = "$env:TEMP\$scriptName"
            Invoke-WebRequest -Uri $scriptUrl -OutFile $tempScript -UseBasicParsing
            & $pythonPath $tempScript
            Remove-Item $tempScript -Force

            if ($appExecutionAlias) {
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\python.exe" -Name "(Default)" -Value $appExecutionAlias."(Default)"
            }
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
