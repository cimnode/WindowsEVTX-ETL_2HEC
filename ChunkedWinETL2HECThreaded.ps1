## REQUIRES version 7 or greater of Powershell

# Handle whatever events are handed it in Windows internal format. (such as from the Get-Event function below)
param(
	[string][Parameter(Mandatory=$True)] $EventFilePath,
	[string] $SecondsMinusEarliest = 1260,
	[string] $SecondsMinusLatest = 60
	)

"Start Time: " + (Get-Date)

if ( -not (Test-Path -Path $EventFilePath -PathType Leaf) ){$(throw "ETL or EVT file not found, (" + $EventFilePath + ") please provide a value on command invocation or from settings file.") }

# How many events should each thread handle. These will be further broken down into HEC batches, with a setting in that file. 500
$EventsPerJob = 2000

# Get settings in file if they exist.
$args = @{}
$args.Add("StartTime", ((Get-Date).AddSeconds(-$SecondsMinusEarliest)))
$args.Add("EndTime", ((Get-Date).AddSeconds(-$SecondsMinusLatest)))
$args.Add("Path", $EventFilePath)

write-host "Event to retrieve { FilePath=" $EventFilePath ", StartTime=" ((Get-Date).AddSeconds(-$SecondsMinusEarliest)) ", EndTime=" ((Get-Date).AddSeconds(-$SecondsMinusLatest))


$WindowsEventData = Get-WinEvent -FilterHashtable $args -oldest

# Swagging the batch size based on time. This will create an easy, best effort batching. That should allow multithreaded HEC routines. (passing the data is serial and bad.)
$JobQuantity = [math]::ceiling($WindowsEventData.count / $EventsPerJob)
$secondsPerJob = [math]::ceiling( ($SecondsMinusEarliest - $SecondsMinusLatest )/$JobQuantity)
write-host "Event retrieval complete: " (Get-Date) ", events" $WindowsEventData.count  ", Jobs: " $JobQuantity  ", seconds per batch:" $secondsPerJob

$job_start_seconds = $SecondsMinusEarliest
$job_end_seconds = $SecondsMinusEarliest - $secondsPerJob
for( $i = 0; $i -lt $JobQuantity; $i++)
{
	write-host "Running batch. Earliest seconds: "$job_start_seconds", Latest seconds: "$job_end_seconds
		
	start-threadjob -ScriptBlock {.\WinETL2HEC.ps1 -EventFilePath "$using:EventFilePath" -SecondsMinusEarliest $using:batch_start_seconds -SecondsMinusLatest $using:batch_end_seconds} 
	
	# This is outside of threaded-job
	$job_start_seconds = $job_end_seconds - 1
	if( ( $job_start_seconds - $secondsPerJob ) -lt $SecondsMinusLatest ) { $job_end_seconds =  $SecondsMinusLatest } else {  $job_end_seconds = $job_start_seconds - $secondsPerJob   }

}
write-host "Waiting for jobs to finish."

get-job | wait-job

write-host "Script complete: "(Get-Date)
