<#
.SYNOPSIS
    Synchronizes two folders: source and replica.
.DESCRIPTION
    This script maintains a full, identical copy of the source folder at the replica folder.
    Synchronization is one-way: after the synchronization, the content of the replica folder
    is modified to exactly match the content of the source folder.
.PARAMETER SourceFolder
    The path to the source folder that needs to be synchronized.
.PARAMETER ReplicaFolder
    The path to the replica folder where the content will be synchronized.
.PARAMETER LogFile
    The path to the log file where operations will be logged.
.EXAMPLE
    .\SyncFolders.ps1 -SourceFolder "C:\Path\To\SourceFolder" -ReplicaFolder "C:\Path\To\ReplicaFolder" -LogFile "C:\Path\To\logfile.log"
#>

param (
    [string]$SourceFolder,
    [string]$ReplicaFolder,
    [string]$LogFile
)

function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Add-Content -Path $LogFile -Value $logMessage
    Write-Output $logMessage
}

function Validate-Path {
    param (
        [string]$Path,
        [string]$ParameterName
    )
    if (-not (Test-Path -Path $Path)) {
        Write-Host "The provided path for $ParameterName '$Path' is invalid. Please provide a valid path."
        exit 1
    }
}

function Sync-Folders {
    param (
        [string]$Source,
        [string]$Replica
    )

    # Get all items in the source folder
    $sourceItems = Get-ChildItem -Path $Source -Recurse -Force

    # Get all items in the replica folder
    $replicaItems = Get-ChildItem -Path $Replica -Recurse -Force

    # Create a hashtable for quick lookup
    $replicaHashTable = @{}
    foreach ($item in $replicaItems) {
        $relativePath = $item.FullName.Substring($Replica.Length)
        $replicaHashTable[$relativePath] = $item
    }

    # Synchronize from source to replica
    foreach ($sourceItem in $sourceItems) {
        $relativePath = $sourceItem.FullName.Substring($Source.Length)
        $replicaItemPath = Join-Path -Path $Replica -ChildPath $relativePath

        if ($sourceItem.PSIsContainer) {
            # Create directory if it does not exist in replica
            if (-not (Test-Path -Path $replicaItemPath)) {
                New-Item -ItemType Directory -Path $replicaItemPath
                Log-Message "Created directory: $replicaItemPath"
            }
        } else {
            # Copy file if it does not exist or is different
            if (-not (Test-Path -Path $replicaItemPath) -or
                (Get-FileHash -Path $sourceItem.FullName).Hash -ne (Get-FileHash -Path $replicaItemPath).Hash) {
                Copy-Item -Path $sourceItem.FullName -Destination $replicaItemPath -Force
                Log-Message "Copied file: $sourceItem.FullName to $replicaItemPath"
            }
        }

        # Remove item from the hashtable to mark it as processed
        $replicaHashTable.Remove($relativePath)
    }

    # Remove items that are in replica but not in source
    foreach ($key in $replicaHashTable.Keys) {
        $itemToRemove = $replicaHashTable[$key]
        if ($itemToRemove.PSIsContainer) {
            Remove-Item -Path $itemToRemove.FullName -Recurse -Force
            Log-Message "Removed directory: $itemToRemove.FullName"
        } else {
            Remove-Item -Path $itemToRemove.FullName -Force
            Log-Message "Removed file: $itemToRemove.FullName"
        }
    }
}

# Validate provided paths
Validate-Path -Path $SourceFolder -ParameterName "SourceFolder"
Validate-Path -Path $ReplicaFolder -ParameterName "ReplicaFolder"

# Ensure the log file directory exists
$logFileDirectory = Split-Path -Parent $LogFile
Validate-Path -Path $logFileDirectory -ParameterName "LogFile Directory"

# Ensure the log file exists
if (-not (Test-Path -Path $LogFile)) {
    New-Item -ItemType File -Path $LogFile -Force
}

# Start the timer
$startTime = Get-Date

# Start synchronization
Log-Message "Starting synchronization from $SourceFolder to $ReplicaFolder"
Sync-Folders -Source $SourceFolder -Replica $ReplicaFolder

# Stop the timer
$endTime = Get-Date
$duration = $endTime - $startTime

# Log completion with timestamp and duration
Log-Message "Synchronization completed in $($duration.TotalMilliseconds) ms"
