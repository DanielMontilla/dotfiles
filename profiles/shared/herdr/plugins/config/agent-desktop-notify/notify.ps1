$eventJson = $env:HERDR_PLUGIN_EVENT_JSON
if (-not $eventJson) { exit 0 }

$event = $eventJson | ConvertFrom-Json
$status = $event.data.agent_status
if (-not $status) { exit 0 }
$status = $status.ToLower()

if ($status -ne "done" -and $status -ne "blocked") { exit 0 }

$contextJson = $env:HERDR_PLUGIN_CONTEXT_JSON
$context = if ($contextJson) { $contextJson | ConvertFrom-Json } else { $null }

$agent = if ($context.focused_pane_agent) { $context.focused_pane_agent } else { "Agent" }

if ($status -eq "done") {
    $title = "${agent} finished"
    $body = ""
} else {
    $title = "${agent} needs attention"
    $body = "Agent is blocked"
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue

$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml(@"
<toast>
    <visual>
        <binding template='ToastGeneric'>
            <text>$title</text>
            <text>$body</text>
        </binding>
    </visual>
</toast>
"@)

$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier().Show($toast)
