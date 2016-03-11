Param ([switch]$m=$false,[string]$v="")

### --- Configuration Starts Here --- ###

$tabDir = "D:\Program Files\Tableau\Tableau Server"
$backupDir = "D:\Program Files\Tableau\Backups"
$bit = 64

### --- Configuration Ends Here. Please don't change anything else --- ###


# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator

   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";

   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;

   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";

   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);

   # Exit from the current, unelevated, process
   exit
   }

#Check Tableau Directory exists
$tabDirExists = Test-Path $tabDir -PathType Container
if (-Not $tabDirExists) {
    $A = Get-Date; Write-Error "[$A] Tableau Directory (tabDir) not found! Exiting" -Category ObjectNotFound
    Exit
}

#Output config to log file
$A = Get-Date; Write-Output "[$A] Getting ready to upgrade Tableau Server" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
$A = Get-Date; Write-Output "[$A] tabDir set to $tabDir" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
$A = Get-Date; Write-Output "[$A] backupDir set to $backupDir" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
$A = Get-Date; Write-Output "[$A] $bit-bit installtion" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
if ($v -ne "")
    {
        $A = Get-Date; Write-Output "[$A] Upgrade set to version $v" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
    }
elseif ($m)
    {
        $A = Get-Date; Write-Output "[$A] Upgrade limited to maintenance upgrade" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
    }

#Create Backup directory
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
#Check Backup Directory exists
$backupDirExists = Test-Path $backupDir -PathType Container
if (-Not $backupDirExists) {
    $A = Get-Date; Write-Error "[$A] Backup Directory (backupDir) not found! Exiting" -Category ObjectNotFound | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
    Exit
}

#Get Tableau Release JSON
$resource = "https://downloads.tableau.com/esdalt/esdalt.json"
$jsonRaw = Invoke-RestMethod -Method Get -Uri $resource

#Check Release JSON was downloaded
$jsonCheck = $jsonRaw -match "angular.callbacks._0\("
if(-Not $jsonCheck)
    {
        $A = Get-Date; Write-Error "[$A] Not able to download release JSON! Exiting" -Category ConnectionError | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
        Exit
    }

#Parse JSON
$jsonRaw = $jsonRaw -replace "angular.callbacks._0\(", "{ ""versions"" : "
$jsonRaw = $jsonRaw -replace "\)\;$", "}"
$json = $jsonRaw | ConvertFrom-Json

#Find installed version number from buildversion.txt in tabDir
$versionDir = Get-ChildItem -Path $tabDir -Directory -name | Where-Object {$_ -like '*.*'} | sort -Descending | select -first 1
$binDir = $tabDir + "\" + $versionDir + "\bin"

##Check tabadmin exists
  $tabadminPath = "$binDir\tabadmin.exe"
  $tabadminExists = Test-Path $tabadminPath -PathType Leaf
  if (-Not $tabadminExists) {
      $A = Get-Date; Write-Error "[$A] Tabadmin not found! Exiting" -Category ObjectNotFound | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
      Exit
  }
##

$versionFile = Get-Content $binDir"\buildversion.txt"
$versionFile[1] -match 'Version.(\d+)\.(\d+)\.(\d+)' | Out-Null;
$version = $matches;
$installedVersion = $version[1] + "." + $version[2] + "." + $version[3]

$A = Get-Date; Write-Output "[$A] Currently you have Tableau Server version $installedVersion installed" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append

if ($v -ne "")
    {
        $v -match '(\d+\.\d+)\.\d+' | Out-Null;
        $mv = $Matches[1];
        $idx = (0..($json.versions.Count-1)) | where {$json.versions[$_].major_version -eq $mv}
        $idxa  = (0..($json.versions[$idx].minor_version.Count-1)) | where {$json.versions[$idx].minor_version[$_].version -eq $v}
        $latestVersion = $json.versions[$idx].minor_version[$idxa].version | select -first 1
        if ($json.versions[0].minor_version[$idx].server_primary_installers[0].name -like "*$bitbit*")
            {
               $downloadLink = $json.versions[$idx].minor_version[$idxa].server_primary_installers[0].download_link
            }
        else
            {
               $downloadLink = $json.versions[$idx].minor_version[$idxa].server_primary_installers[1].download_link
            }
        $newDir = $json.versions[$idx].major_version
        $A = Get-Date; Write-Output "[$A] Chosen version of Tableau Server is $latestVersion" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
    }
elseif ($m)
    {
        $idx = (0..($json.versions.Count-1)) | where {$json.versions[$_].major_version -eq $version[1]+"."+$version[2]}
        $idxa = (0..($json.versions[0].minor_version.Count-1)) | where {$json.versions[0].minor_version[$_].server_primary_installers.Count -gt 0} | select -first 1
        $latestVersion = $json.versions[$idx].minor_version[$idxa].version | select -first 1
        if ($json.versions[0].minor_version[$idx].server_primary_installers[0].name -like "*$bitbit*")
            {
                $downloadLink = $json.versions[$idx].minor_version[$idxa].server_primary_installers[0].download_link
            }
        else
            {
                $downloadLink = $json.versions[$idx].minor_version[$idxa].server_primary_installers[1].download_link
            }
        $newDir = $json.versions[$idx].major_version
        $A = Get-Date; Write-Output "[$A] Latest maintenance release of Tableau Server is $latestVersion" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
    }
else {
        $idx = (0..($json.versions[0].minor_version.Count-1)) | where {$json.versions[0].minor_version[$_].server_primary_installers.Count -gt 0} | select -first 1
        $latestVersion = $json.versions[0].minor_version[$idx].version | select -first 1
        if ($json.versions[0].minor_version[$idx].server_primary_installers[0].name -like "*$bitbit*")
            {
                $downloadLink = $json.versions[0].minor_version[$idx].server_primary_installers[0].download_link
            }
        else
            {
                $downloadLink = $json.versions[0].minor_version[$idx].server_primary_installers[1].download_link
            }
        $newDir = $json.versions[0].major_version
        $A = Get-Date; Write-Output "[$A] Latest version of Tableau Server is $latestVersion" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
    }

#Check if an upgrade is required
if ($latestVersion -le $installedVersion)
    {
        $A = Get-Date; Write-Output "[$A] Looks like you're up to date! Exiting" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
        Exit
    }

#Download latest installation file
$A = Get-Date; Write-Output "[$A] Getting ready to update $bit-bit Tableau Server" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append

$downloadDestination = $tabDir+"\TableauServer.exe"
$A = Get-Date; Write-Output "[$A] Downloading..." | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
Invoke-WebRequest $downloadLink -OutFile $downloadDestination
$A = Get-Date; Write-Output "[$A] Upgrading..." | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append

#Stop Tableau Server
$A = Get-Date; Write-Output "[$A] Stopping Tableau Server..." | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
& $binDir'\tabadmin' stop | Out-Null

#Backup Tableau Server to backupDir
$A = Get-Date; Write-Output "[$A] Backing up Tableau Server to $backupDir\upgradeBackup.tsbak" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
& $binDir'\tabadmin' backup $backupDir'\upgradeBackup.tsbak' | Out-Null

#Uninstall existing Tableau Server
$A = Get-Date; Write-Output "[$A] Uninstalling version $installedVersion" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
& $tabDir'\unins000.exe' /verysilent | Out-Null

#Run downloaded installer
$A = Get-Date; Write-Output "[$A] Installing version $latestVersion" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
& $downloadDestination /verysilent /dir=$tabDir | Out-Null

#Start new installation
$binDir = $tabDir + "\" + $newDir + "\bin"
& $binDir'\tabadmin' start | Out-Null

$A = Get-Date; Write-Output "[$A] Upgrade Complete!" | Tee-Object -file "$tabDir\UpgradeLog.txt" -Append
exit
