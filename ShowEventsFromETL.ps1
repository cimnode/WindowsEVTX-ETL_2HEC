#This file fill read 1 minute of logs starting 2 minutes ago.
$args = @{}
$args.Add("StartTime", ((Get-Date).AddMinutes(-2)))
$args.Add("EndTime", ((Get-Date).AddMinutes(-1)))
$args.Add("Path", "c:\windows\System32\Winevt\Logs\Microsoft-Windows-DNSServer-Analytical.etl")

Get-WinEvent -FilterHashtable $args -oldest
