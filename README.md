# SyncFolders PowerShell Script

## Description

This PowerShell script synchronizes the content of a source folder with a replica folder. The script maintains a full, identical copy of the source folder in the replica folder. Synchronization is one-way, meaning that the content of the replica folder is modified to exactly match the content of the source folder after the synchronization.

## Usage

The script requires three arguments:

1. **SourceFolder**: The path to the source folder.
2. **ReplicaFolder**: The path to the replica folder.
3. **LogFile**: The path to the log file where operations will be logged.

### Example

```powershell
.\SyncFolders.ps1 -SourceFolder "C:\Path\To\SourceFolder" -ReplicaFolder "C:\Path\To\ReplicaFolder" -LogFile "C:\Path\To\logfile.log"
```
