param(
  [string]$TaskName = 'SmartJudi-Sync-Agent',
  [string]$XmlPath = "$PSScriptRoot\task_scheduler_hourly.xml"
)

if (!(Test-Path $XmlPath)) {
  throw "XML not found: $XmlPath"
}

# Import task (will prompt for credentials)
Register-ScheduledTask -TaskName $TaskName -Xml (Get-Content $XmlPath | Out-String) -Force

Write-Host "Imported scheduled task: $TaskName"
