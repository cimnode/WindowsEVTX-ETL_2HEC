# WindowsEVTX-ETL_2HEC
This script **requires** Powershell 7 to run. Powershell 7 vastly improves the handling of Windows Events and Trace files. https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2

1. Download and unzip files.
2. Edit SplunkSettings.json with appropriate values.
  - HEC token must already be created
  - Follow JSON format exactly
3. Unblock ps1 scripts so they can be run. (Run commands from within directory containing files to be unblocked.)
```
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

  Unblock-File -path .\Run_Win_ETL-EVTX_2HEC_Threaded.ps1
  Unblock-File -path .\WinETL-EVTX2HEC.ps1
```  
4. Run using pwsh (Powershell 7) Specify values for EventFilePath, SecondsMinusEarliest and SecondsMinusLatest. (Default Windows is very short.)
```
   .\Run_Win_ETL-EVTX_2HEC_Threaded.ps1 -EventFilePath C:\Windows\System32\winevt\Logs\Application.evtx -SecondsMinusEarliest 3000000 -SecondsMinusLatest 0
   .\Run_Win_ETL-EVTX_2HEC_Threaded.ps1 -EventFilePath C:\Windows\System32\winevt\Logs\RemoteDesktopServices-RemoteFX-SessionLicensing-Debug.etl -SecondsMinusEarliest 3000000 -SecondsMinusLatest 0
```
SecondsMinusEarliest and SecondsMinusLatest set the time range the events are pulled from. Earliest would be the oldest 'TimeCreated' value looking backwards in seconds. And latest would be the 'TimeCreated' of the newest event. 
If the EventFilePath has a space, enclose it in double quotes.
