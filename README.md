# WindowsDNS-ETL2HEC

1. Download and unzip files.
2. Edit SplunkSettings.json with appropriate values.
  - HEC token must already be created
  - Follow JSON format exactly
3. Unblock ps1 scripts so they can be run.
```
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

  Unblock-File -path .\Run_Win_ETL-EVTX_2HEC_Threaded.ps1
  Unblock-File -path .\WinETL-EVTX2HEC.ps1
```  
4. Run using pwsh (Powershell 7)
```
   .\Run_Win_ETL-EVTX_2HEC_Threaded.ps1 -EventFilePath C:\Windows\System32\winevt\Logs\Application.evtx -SecondsMinusEarliest 3000000 -SecondsMinusLatest 0
   .\Run_Win_ETL-EVTX_2HEC_Threaded.ps1 -EventFilePath C:\Windows\System32\winevt\Logs\RemoteDesktopServices-RemoteFX-SessionLicensing-Debug.etl -SecondsMinusEarliest 3000000 -SecondsMinusLatest 0
```
