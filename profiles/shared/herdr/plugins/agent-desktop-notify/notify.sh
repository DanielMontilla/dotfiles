#!/bin/bash
event_json="$HERDR_PLUGIN_EVENT_JSON"
context_json="$HERDR_PLUGIN_CONTEXT_JSON"

exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File notify.ps1 "$event_json" "$context_json"
