## REQUIRES version 7 or greater of Powershell

# Handle whatever events are handed it in Windows internal format. (such as from the Get-Event function below)
param(
	[string] $SplunkURL, 
	[string] $SplunkHECToken,
	[string] $SplunkIndex,
	[string][Parameter(Mandatory=$True)] $EventFilePath,
	[string] $SecondsMinusEarliest = 1260,
	[string] $SecondsMinusLatest = 60
	)

"Start Time: " + (Get-Date)

if ( -not (Test-Path -Path $EventFilePath -PathType Leaf) ){$(throw "ETL or EVT file not found, (" + $EventFilePath + ") please provide a value on command invocation or from settings file.") }


$HECBatchSize = 500

# Get settings in file if they exist.
$ScriptFilePath = Split-Path $script:MyInvocation.MyCommand.Path
$ScriptFilePath += "\SplunkSettings.json"
if (Test-Path -Path $ScriptFilePath -PathType Leaf) {
	$SplunkSettingsObject = Get-Content $ScriptFilePath | ConvertFrom-Json
	if( (-not $SplunkURL) -and $SplunkSettingsObject.SplunkURL ){$SplunkURL = $SplunkSettingsObject.SplunkURL } 
	if( (-not $SplunkHECToken) -and $SplunkSettingsObject.SplunkHECToken ){ $SplunkHECToken = $SplunkSettingsObject.SplunkHECToken}
	if( (-not $SplunkIndex) -and $SplunkSettingsObject.SplunkIndex ){$SplunkIndex = $SplunkSettingsObject.SplunkIndex}
}
if( (-not $SplunkURL) -or (-not $SplunkHECToken)){$(throw "SplunkHECToken and SplunkURL are mandatory, please provide a value on command invocation or from settings file.") }

	$args = @{}
	$args.Add("StartTime", ((Get-Date).AddSeconds(-$SecondsMinusEarliest)))
	$args.Add("EndTime", ((Get-Date).AddSeconds(-$SecondsMinusLatest)))
	$args.Add("Path", $EventFilePath)

"Event to retrieve { FilePath=" + $EventFilePath + ", StartTime=" + ((Get-Date).AddSeconds(-$SecondsMinusEarliest)) + ", EndTime=" + ((Get-Date).AddSeconds(-$SecondsMinusLatest))

$WindowsEventData = Get-WinEvent -FilterHashtable $args -oldest

"Event retrieval complete: " + (Get-Date)

# Process the event logs handed to function and begin forwarding. Batches should be sent in groups of 50.
$i = 1
foreach( $eventObject in $WindowsEventData )
{
	# May see some errors here about maxdepth, but it appears to be circular reference of no value.
	$eventData = Select-Object -InputObject $eventObject  -Property * | ConvertTo-Json -Compress -Depth 10 -WarningAction SilentlyContinue
	 
	$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$headers.Add("Authorization", 'Splunk ' + $SplunkHECToken)

	$body += '{"event":'+ $eventData  +', "index":"'+$SplunkIndex+'","host":"' + $eventObject.MachineName + '","sourcetype":"WindowsEvent","source":"' + $EventFilePath.Replace("\","\\") + '","time":"'+ $(Get-Date -Date $eventObject.TimeCreated -UFormat %s) + '"}'
	
	if( (($i % $HECBatchSize) -eq  0) -or ($i -eq ($WindowsEventData.Count)))
	{
			$response = Invoke-RestMethod -Uri $SplunkURL  -Method Post -Headers $headers -Body $body -SkipCertificateCheck
			"HEC Response Code:'" + $response.code + "' text:'"+ $response.text + "' final record number of batch:" + ($i) 
			$body = ''
	}
	$i++
}

"Script complete: " + (Get-Date)
