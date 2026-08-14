$eventJson = $args[0]
if (-not $eventJson) { exit 0 }

$event = $eventJson | ConvertFrom-Json
$status = $event.data.agent_status
if (-not $status) { exit 0 }
$status = $status.ToLower()

if ($status -ne "done") { exit 0 }

$contextJson = $args[1]
$context = if ($contextJson) { $contextJson | ConvertFrom-Json } else { $null }
$agent = if ($context.focused_pane_agent) { $context.focused_pane_agent } else { "Agent" }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.BalloonTipTitle = "${agent} finished"
$notify.BalloonTipText = "Herdr"
$notify.Visible = $true
$notify.ShowBalloonTip(8000)

Start-Sleep 9
