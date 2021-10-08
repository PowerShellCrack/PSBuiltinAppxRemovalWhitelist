<#
	.SYNOPSIS
        Removes unneeded apps from Windows 10 and Windows 11

    .DESCRIPTION
		Removes unneeded apps from Windows 10 and Windows 11 using whitelist
        Can be used in:
            - MECM Tasksequences (with progress bar iteration)
            - MECM Software Delivery
            - Intune Script (for MDM & Autopilot)

    .NOTES
        Author		: Dick Tracy <richard.tracy@hotmail.com>
	    Source		: https://github.com/PowerShellCrack/AutopilotTimeZoneSelectorUI
        Version		: 2.0.1
        README      : Review README.md for more details and configurations
        IMPORTANT   : By using this script or parts of it, you have read and accepted the DISCLAIMER.md and LICENSE agreement

    .LINK
        https://www.scconfigmgr.com/2016/03/01/remove-built-in-apps-when-creating-a-windows-10-reference-image/
        https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/inbox-network-drivers
        https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/features-on-demand-non-language-fod

    .PARAMETER AppendWhiteListedAppX
        Array --> Default is Null
        Adds to WhiteListedAppX list. Example would be to add different language pack
        Current list includes:
            Microsoft.DesktopAppInstaller
            Microsoft.WindowsStore
            Microsoft.StorePurchaseApp
            Microsoft.MSPaint
            Microsoft.Windows.Photos
            Microsoft.MicrosoftStickyNotes
            Microsoft.WindowsAlarms
            Microsoft.WindowsCalculator
            Microsoft.WindowsSoundRecorder
            Microsoft.RemoteDesktop
            Microsoft.CompanyPortal
            Microsoft.Office.OneNote
            Microsoft.SurfaceHub
            Microsoft.Office.Sway
            Microsoft.WindowsCamera
            Microsoft.Todos
            Microsoft.ScreenSketch
            Microsoft.MsixPackagingTool
            Microsoft.Whiteboard
            MicrosoftTeams
            Microsoft.OneDriveSync
            Windows.PrintDialog
            Microsoft.Paint
            Microsoft.MicrosoftEdge.Stable


    .PARAMETER AppendWhiteListOnDemand
        Array --> Default is Null
        Adds to AppendWhiteListOnDemand list. Example would be to add different language pack
        Current list includes:
            NetFX3
            Tools.Graphics.DirectX
            Tools.DeveloperMode.Core
            Language
            InternetExplorer
            ContactSupport
            OneCoreUAP
            WindowsMediaPlayer
            Rsat
            Powershell
            Notepad
            Hello.Face
            WordPad
            XPS.Viewer
            StepsRecorder
            Windows.Client.ShellComponents
            #"QuickAssist
            en-US

    .PARAMETER SupportedOSBuilds
        Array --> Default to current list:
            10.0.10240 --> 1507
            10.0.10586 --> 1511
            10.0.14393 --> 1607
            10.0.15063 --> 1703
            10.0.16299 --> 1709
            10.0.17134 --> 1803
            10.0.17763 --> 1809
            10.0.18362 --> 1903
            10.0.18363 --> 1909
            10.0.19041 --> 2004
            10.0.19042 --> 20H2
            10.0.19043 --> 21H1
            10.0.22473 -->Win11 (insider)
        Parameter is controls whether the script should run on a version of windows.

    .PARAMETER TestOnly
        Only simulates removal or applications, then outputs the apps to be removed

    #.PARAMETER RemoveDuplicateAppx

    .EXAMPLE
        .\RemoveBuiltinAppxWhitelist.ps1 -TestOnly

	.EXAMPLE
		APPX RECOVERY:
    		Remove Built-in apps when creating a Windows 10 reference image

            In case you have removed them for good, you can try to restore the files using installation medium as follows
            New-Item C:\Mnt -Type Directory | Out-Null
            dism /Mount-Image /ImageFile:D:\sources\install.wim /index:1 /ReadOnly /MountDir:C:\Mnt
            robocopy /S /SEC /R:0 "C:\Mnt\Program Files\WindowsApps" "C:\Program Files\WindowsApps"
            dism /Unmount-Image /Discard /MountDir:C:\Mnt
            Remove-Item -Path C:\Mnt -Recurse

        FOD RECOVERY:
            Add-WindowsCapability -Online -Name Microsoft.Windows.Notepad~~~~0.0.1.0
            DISM /Online /Add-Capability /CapabilityName:App.Support.QuickAssist~~~~0.0.1.0 /Source:C:\Mnt
#>


Param(
    [string[]]$AppendWhiteListedAppX = @(),
    [string[]]$AppendWhiteListOnDemand = @(),
    [string[]]$SupportedOSBuilds = @('10.0.10240', #1507
                                    '10.0.10586', #1511
                                    '10.0.14393', #1607
                                    '10.0.15063', #1703
                                    '10.0.16299', #1709
                                    '10.0.17134', #1803
                                    '10.0.17763', #1809
                                    '10.0.18362', #1903
                                    '10.0.18363', #1909
                                    '10.0.19041', #2004
                                    '10.0.19042', #20H2
                                    '10.0.19043', #21H1
                                    '10.0.22473'  #Win11 (insider)
                                    ),
    [switch]$TestOnly
    #[switch]$RemoveDuplicateAppx
)

#*=============================================
##* Runtime Function - REQUIRED
##*=============================================
#region FUNCTION: Check if running in WinPE
Function Test-WinPE{
    return Test-Path -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlset\Control\MiniNT
}
#endregion

#region FUNCTION: Check if running in ISE
Function Test-IsISE {
    # try...catch accounts for:
    # Set-StrictMode -Version latest
    try {
        return ($null -ne $psISE);
    }
    catch {
        return $false;
    }
}
#endregion

#region FUNCTION: Check if running in Visual Studio Code
Function Test-VSCode{
    if($env:TERM_PROGRAM -eq 'vscode') {
        return $true;
    }
    Else{
        return $false;
    }
}
#endregion
Function Get-ScriptPath {
    <#
        .SYNOPSIS
            Finds the current script path even in ISE or VSC
        .LINK
            Test-VSCode
            Test-IsISE
    #>
    [CmdletBinding()]
    param(
        [switch]$Parent
    )

    Begin{}
    Process{
        if ($PSScriptRoot -eq "")
        {
            if (Test-IsISE)
            {
                $ScriptPath = $psISE.CurrentFile.FullPath
            }
            elseif(Test-VSCode){
                $context = $psEditor.GetEditorContext()
                $ScriptPath = $context.CurrentFile.Path
            }Else{
                $ScriptPath = (Get-location).Path
            }
        }
        else
        {
            $ScriptPath = $PSCommandPath
        }
    }
    End{

        If($Parent){
            Split-Path $ScriptPath -Parent
        }Else{
            $ScriptPath
        }
    }

}
#endregion

Function Get-SMSTSENV{
    [CmdletBinding()]
    param(
        [switch]$LogPath,
        [switch]$NoWarning
    )

    Begin{
        ## Get the name of this function
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
    }
    Process{
        try{
            # Create an object to access the task sequence environment
            $Script:tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
            #test if variables exist
            $tsenv.GetVariables()  #| % { Write-Output "$ScriptName - $_ = $($tsenv.Value($_))" }
        }
        catch{
            If(${CmdletName}){$prefix = "${CmdletName} ::" }Else{$prefix = "" }
            If(!$NoWarning){Write-Warning ("{0}Task Sequence environment not detected. Running in stand-alone mode." -f $prefix)}

            #set variable to null
            $Script:tsenv = $null
        }
        Finally{
            #set global Logpath
            if ($tsenv){
                #grab the progress UI
                $Script:TSProgressUi = New-Object -ComObject Microsoft.SMS.TSProgressUI

                # Query the environment to get an existing variable
                # Set a variable for the task sequence log path
                #$UseLogPath = $tsenv.Value("LogPath")
                $UseLogPath = $tsenv.Value("_SMSTSLogPath")

                # Convert all of the variables currently in the environment to PowerShell variables
                $tsenv.GetVariables() | ForEach-Object { Set-Variable -Name "$_" -Value "$($tsenv.Value($_))" }
            }
            Else{
                $UseLogPath = $env:Temp
            }
        }
    }
    End{
        If($LogPath){return $UseLogPath}
    }
}

Function Format-ElapsedTime($ts) {
    $elapsedTime = ""
    if ( $ts.Minutes -gt 0 ){$elapsedTime = [string]::Format( "{0:00} min. {1:00}.{2:00} sec.", $ts.Minutes, $ts.Seconds, $ts.Milliseconds / 10 );}
    else{$elapsedTime = [string]::Format( "{0:00}.{1:00} sec.", $ts.Seconds, $ts.Milliseconds / 10 );}
    if ($ts.Hours -eq 0 -and $ts.Minutes -eq 0 -and $ts.Seconds -eq 0){$elapsedTime = [string]::Format("{0:00} ms.", $ts.Milliseconds);}
    if ($ts.Milliseconds -eq 0){$elapsedTime = [string]::Format("{0} ms", $ts.TotalMilliseconds);}
    return $elapsedTime
}

Function Format-DatePrefix{
    [string]$LogTime = (Get-Date -Format 'HH:mm:ss.fff').ToString()
	[string]$LogDate = (Get-Date -Format 'MM-dd-yyyy').ToString()
    return ($LogDate + " " + $LogTime)
}


Function Write-LogEntry{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(Mandatory=$false,Position=2)]
		[string]$Source = '',
        [parameter(Mandatory=$false)]
        [ValidateSet(0,1,2,3,4)]
        [int16]$Severity,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$OutputLogFile,

        [parameter(Mandatory=$false)]
        [switch]$Outhost
    )
    Begin{
        ## Get the name of this function
        [string]$LogTime = (Get-Date -Format 'HH:mm:ss.fff').ToString()
    	[string]$LogDate = (Get-Date -Format 'MM-dd-yyyy').ToString()
    	[int32]$script:LogTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes
    	[string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias
        #  Get the file name of the source script
    }
    Process{
        Try {
    	    If ($script:MyInvocation.Value.ScriptName) {
    		    [string]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf -ErrorAction 'Stop'
    	    }
    	    Else {
    		    [string]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf -ErrorAction 'Stop'
    	    }
        }
        Catch {
    	    $ScriptSource = ''
        }

        If(!$Severity){$Severity = 1}
        $LogFormat = "<![LOG[$Message]LOG]!>" + "<time=`"$LogTimePlusBias`" " + "date=`"$LogDate`" " + "component=`"$ScriptSource`" " + "context=`"$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + "type=`"$Severity`" " + "thread=`"$PID`" " + "file=`"$ScriptSource`">"

        # Add value to log file
        try {
            Out-File -InputObject $LogFormat -Append -NoClobber -Encoding Default -FilePath $OutputLogFile -ErrorAction Stop
        }
        catch {
            Write-Output ("[{0}] [{1}] :: Unable to append log entry to [{2}]: {3}" -f $LogTimePlusBias,$ScriptSource,$OutputLogFile,$_.Exception.Message)
        }

        If($Outhost){
            If($Source){
                $OutputMsg = ("[{0}] [{1}] :: {2}" -f $LogTimePlusBias,$Source,$Message)
            }
            Else{
                $OutputMsg = ("[{0}] [{1}] :: {2}" -f $LogTimePlusBias,$ScriptSource,$Message)
            }

            Switch($Severity){
                0       {Write-Output $OutputMsg}
                1       {Write-Output $OutputMsg}
                2       {Write-Warning $OutputMsg}
                3       {Write-Output $OutputMsg}
                4       {If($VerbosePreference){Write-Verbose $OutputMsg}}
                default {Write-Output $OutputMsg}
            }
        }
    }
    End{}
}

function Show-ProgressStatus
{
    <#
    .SYNOPSIS
        Shows task sequence secondary progress of a specific step

    .DESCRIPTION
        Adds a second progress bar to the existing Task Sequence Progress UI.
        This progress bar can be updated to allow for a real-time progress of
        a specific task sequence sub-step.
        The Step and Max Step parameters are calculated when passed. This allows
        you to have a "max steps" of 400, and update the step parameter. 100%
        would be achieved when step is 400 and max step is 400. The percentages
        are calculated behind the scenes by the Com Object.

    .PARAMETER Message
        The message to display the progress
    .PARAMETER Step
        Integer indicating current step
    .PARAMETER MaxStep
        Integer indicating 100%. A number other than 100 can be used.
    .INPUTS
         - Message: String
         - Step: Long
         - MaxStep: Long
    .OUTPUTS
        None
    .EXAMPLE
        Set's "Custom Step 1" at 30 percent complete
        Show-ProgressStatus -Message "Running Custom Step 1" -Step 100 -MaxStep 300

    .EXAMPLE
        Set's "Custom Step 1" at 50 percent complete
        Show-ProgressStatus -Message "Running Custom Step 1" -Step 150 -MaxStep 300
    .EXAMPLE
        Set's "Custom Step 1" at 100 percent complete
        Show-ProgressStatus -Message "Running Custom Step 1" -Step 300 -MaxStep 300
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string] $Message,
        [Parameter(Mandatory=$true)]
        [int]$Step,
        [Parameter(Mandatory=$true)]
        [int]$MaxStep,
        [string]$SubMessage
    )

    Begin{

        If($SubMessage){
            $StatusMessage = ("{0} [{1}]" -f $Message,$SubMessage)
        }
        Else{
            $StatusMessage = $Message

        }
    }
    Process
    {
        If($Script:tsenv){
            $Script:TSProgressUi.ShowActionProgress(`
                $Script:tsenv.Value("_SMSTSOrgName"),`
                $Script:tsenv.Value("_SMSTSPackageName"),`
                $Script:tsenv.Value("_SMSTSCustomProgressDialogMessage"),`
                $Script:tsenv.Value("_SMSTSCurrentActionName"),`
                [Convert]::ToUInt32($Script:tsenv.Value("_SMSTSNextInstructionPointer")),`
                [Convert]::ToUInt32($Script:tsenv.Value("_SMSTSInstructionTableSize")),`
                $StatusMessage,`
                $Step,`
                $Maxstep)
        }
        Else{
            Write-Progress -Activity "$Message ($Step of $Maxstep)" -Status $StatusMessage -PercentComplete (($Step / $Maxstep) * 100) -id 1
        }
    }
    End{}
}



##*===========================================================================
##* VARIABLES
##*===========================================================================
$WhiteListedAppX = @(
    "Microsoft.DesktopAppInstaller",    # REQUIRED
    "Microsoft.WindowsStore",           # REQUIRED
    "Microsoft.StorePurchaseApp",       # REQUIRED
    "Microsoft.MSPaint",
    "Microsoft.Windows.Photos",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCalculator",      # Windows 10 (1511) & higher
    #"Microsoft.WindowsCommunicationsApps", # Mail, Calendar etc
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.RemoteDesktop",
    "Microsoft.CompanyPortal",          # Intune Managed Device
    "Microsoft.Office.OneNote",
    "Microsoft.SurfaceHub",
    "Microsoft.Office.Sway",
    "Microsoft.WindowsCamera",
    "Microsoft.Todos",
    "Microsoft.ScreenSketch",
    "Microsoft.MsixPackagingTool",
    "Microsoft.Whiteboard",
    "MicrosoftTeams",                   # Windows 10 (20H2) & Windows 11
    "Microsoft.OneDriveSync",           # Windows 11
    "Windows.PrintDialog",              # Windows 11
    "Microsoft.Paint",                  # Windows 11 (renamed from MSPaint)
    "Microsoft.MicrosoftEdge.Stable"    # Windows 11
)

$WhiteListFeatureOnDemand = @(
    "Kernel"
    "NetFX3",
    "Tools.Graphics.DirectX",
    "Tools.DeveloperMode.Core",
    "Language",
    "InternetExplorer",
    "ContactSupport",
    "OneCoreUAP",
    "WindowsMediaPlayer",
    "Rsat",                             # Windows 10, version 1809 and later
    "Powershell",                       # Windows 10, version 2004 and later
    "Notepad",                          # Windows Insider Preview Build 21337 and later
    "Hello.Face",
    "WordPad",                          # Windows 10, version 2004 and later
    "XPS.Viewer",
    "Print",
    "StepsRecorder",                    # Windows 10, version 2004 and later
    "Windows.Client.ShellComponents",   # Windows 10, version 2004 and later
    #"QuickAssist",                      # Windows 10, version 1607 and later
    "en-US"
)

# Use function to get paths because Powershell ISE and other editors have different results
$scriptPath = Get-ScriptPath
[string]$scriptName = Split-Path $scriptPath -Leaf
[string]$scriptBaseName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)

$OSInfo = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber
[int]$OSBuildNumber = $OSInfo.BuildNumber

# build log name
[string]$FileName = $scriptBaseName +'.log'
# build global log filepath
$LogFilePath = Join-Path (Get-SMSTSENV -LogPath -NoWarning) -ChildPath $FileName
Write-Output "logging to file: $LogFilePath"

# Add additional log entry parameters that will be used in all commands
$LogEntryParams = @{
    Source = $scriptBaseName
    OutputLogFile = $LogFilePath
    Outhost = $true
}

If(Test-WinPE){
    Write-LogEntry -Message "Unable to process appx removal while running in WinPE" @LogEntryParams
    Exit 0
}

If($OSInfo.version -notin $SupportedOSBuilds){
    Write-LogEntry -Message ("Unable to process appx removal because the Windows OS version [{0}] was not tested" -f $OSInfo.version) @LogEntryParams
    Exit -1
}
##*===========================================================================
##* MAIN
##*===========================================================================
# Get a list of all apps
Write-LogEntry -Message "Starting built-in AppxPackage and AppxProvisioningPackage removal process..." @LogEntryParams
$AllUserAppxItems = Get-AppxPackage -PackageTypeFilter Bundle -AllUsers | Sort-Object -Property Name
<#
$AllUserAppxItems.Count
$AllUserAppxItems.Name

If($AppendWhiteListedAppX.Count -gt 0){
    $AllWhiteListedAppxItems = ($WhiteListedAppX += $AppendWhiteListedAppX) -join "|"
}Else{
    $AllWhiteListedAppxItems = $WhiteListedAppX -join "|"
}

$RemoveAppxItems = Get-AppxPackage -PackageTypeFilter Bundle -AllUsers | Where {$_.Name -notmatch $AllWhiteListedAppxItems} | Sort-Object -Property Name
$RemoveAppxItems.Count
$RemoveAppxItems.Name
#>

# Combine White list of appx packages to keep installed
If($AppendWhiteListedAppX.Count -gt 0){
    $AllWhiteListedAppxItems = $WhiteListedAppX += $AppendWhiteListedAppX
}Else{
    $AllWhiteListedAppxItems = $WhiteListedAppX
}

# set counts
$p = 1
$f = 1
# Define arrays for collections (used for out in testonly parameter)
$RemovedAppxCollection = @()
$RemovedProvisionedAppxCollection = @()
$RemovedFODCollection = @()

If($PSBoundParameters.ContainsKey('TestOnly')){Write-LogEntry -Message "TESTING ONLY" @LogEntryParams}

# Loop through the list of All installed appx packages
<# TESTS
    $App = $AllUserAppxItems[0]
    $App = $AllUserAppxItems[79] #<-- Microsoft.ZuneMusic_2019.21061.10121.0_neutral_~_8wekyb3d8bbwe; does exist as provisioned package
    $App = $AllUserAppxItems[80] #<-- Microsoft.ZuneMusic_8wekyb3d8bbwe; does NOT exist as provisioned package
    $App = $AllUserAppxItems[83] #<-- PaloAltoNetworks.GlobalProtect_5.2.6007.0_neutral_~_rn9aeerfb38dg; does NOT exist as provisioned package
#>
foreach ($App in $AllUserAppxItems)
{
    # Status is what shows up in MDT progressUI
    Show-ProgressStatus `
                -Message ("Removing all users appx") `
                -SubMessage ("{0}" -f $App.Name) `
                -Step $p `
                -MaxStep $AllUserAppxItems.count

    # If application name not in appx package white list, remove AppxPackage and AppxProvisioningPackage
    if (($App.Name -in $AllWhiteListedAppxItems))
    {
        $status = "Skipping excluded application package: $($App.Name)"
        Write-LogEntry -Message $status @LogEntryParams
    }
    else {
        # Gather system provisioning package names
        #$AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App.Name } | Select-Object -ExpandProperty PackageName
        $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -eq $App.PackageFullName } | Select-Object -ExpandProperty PackageName

        # Attempt to remove AppxPackage
        $status = "Removing application package: $($App.PackageFullName)"
        Write-LogEntry -Message $status @LogEntryParams
        try {
            If($PSBoundParameters.ContainsKey('TestOnly') )
            {
                Write-Output "SIMULATED COMMAND: Remove-AppxPackage -Package $($App.PackageFullName) -AllUsers -ErrorAction Stop"
            }
            Else {
                Remove-AppxPackage -Package $App.PackageFullName -AllUsers -ErrorAction Stop | Out-Null
                Write-LogEntry -Message "Successfully removed application package: $($App.PackageFullName)" @LogEntryParams
            }
            $RemovedAppxCollection += $App.PackageFullName
        }
        catch [System.Exception] {
            Write-LogEntry -Message "Failed removing AppxPackage: $($_.Exception.Message)" -Severity 3 @LogEntryParams
        }

        # Attempt to remove AppxProvisioningPackage
        if ($null -ne $AppProvisioningPackageName)
        {
            Write-LogEntry -Message "Removing application provisioning package: $($AppProvisioningPackageName)" @LogEntryParams
            try {
                If($PSBoundParameters.ContainsKey('TestOnly') )
                {
                    Write-Output "SIMULATED COMMAND: Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop"
                }
                Else {
                    Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop | Out-Null
                    Write-LogEntry -Message ("Successfully removed application provisioning package: $AppProvisioningPackageName") @LogEntryParams
                }
                $RemovedProvisionedAppxCollection += $AppProvisioningPackageName
            }
            catch [System.Exception] {
                Write-LogEntry -Message "Failed removing AppxProvisioningPackage: $($_.Exception.Message)" -Severity 3 @LogEntryParams
            }
        }
        else {
            Write-LogEntry -Message "Unable to locate AppxProvisioningPackage for app: $($App.Name)" @LogEntryParams
        }

    }

    $p++
}

Write-LogEntry -Message ("Removed {0} built-in AppxPackage and AppxProvisioningPackage" -f $c) @LogEntryParams


# White list of Features On Demand V2 packages
Write-LogEntry -Message "Starting Features on Demand V2 removal process" @LogEntryParams
If($AppendWhiteListOnDemand.count -gt 0){
    $AllWhiteListOnDemandItems = ($WhiteListFeatureOnDemand += $AppendWhiteListOnDemand) -join "|"
}Else{
    $AllWhiteListOnDemandItems = $WhiteListFeatureOnDemand -join "|"
}

# Get Features On Demand that should be removed
<# TESTS
    $AllInstalledFeatures = Get-WindowsCapability -Online | Where-Object { $_.State -like "Installed"} | Select-Object -ExpandProperty Name
    $AllInstalledFeatures.count
    $RemoveFodItems = Get-WindowsCapability -Online | Where-Object { $_.Name -notmatch $AllWhiteListOnDemandItems -and $_.State -like "Installed"} | Select-Object -ExpandProperty Name
    $RemoveFodItems.count
#>
try {

    # Handle cmdlet limitations for older OS builds
    if ($OSBuildNumber -le "16299") {
        $RemoveFodItems = Get-WindowsCapability -Online -ErrorAction Stop | Where-Object { $_.Name -notmatch $AllWhiteListOnDemandItems -and $_.State -eq "Installed"}
    }
    else {
        $RemoveFodItems = Get-WindowsCapability -Online -LimitAccess -ErrorAction Stop | Where-Object { $_.Name -notmatch $AllWhiteListOnDemandItems -and $_.State -eq "Installed"}
    }

    # Feature on Demand includes drivers for both ethernet and wifi drivers.
    # We need to determine if those are drivers are in use and not remove them
    $NetworkDrivers = ( (Get-NetAdapter).DriverFilename | ForEach-Object{If($_){$_ -replace ".sys",""}} ) -join "|"
    $RemoveFodItems = $RemoveFodItems | Where-Object {$_.Name -notmatch $NetworkDrivers}

    #TEST $Feature = $RemoveFodItems[0]
    #TEST $Feature = $RemoveFodItems[31]
    foreach ($Feature in $RemoveFodItems)
    {
         # Status is what shows up in MDT progressUI
         Show-ProgressStatus `
                     -Message ("Removing Feature on Demand") `
                     -SubMessage ("{0}" -f $Feature.Name) `
                     -Step $f `
                     -MaxStep $RemoveFodItems.count

        $RemovedFODCollection += $Feature.Name
        try {
            Write-LogEntry -Message "Removing Feature on Demand V2 package: $($Feature.Name)" @LogEntryParams
            If($PSBoundParameters.ContainsKey('TestOnly') )
            {
                Write-Output "SIMULATED COMMAND: Remove-WindowsCapability -Name $($Feature.Name) -Online -ErrorAction Stop"
            }
            Else {
                $Feature | Remove-WindowsCapability -Online -ErrorAction Stop | Out-Null
                Write-LogEntry -Message "Successfully removed Feature on Demand V2 package: $($Feature.Name)" @LogEntryParams
            }
        }
        catch [System.Exception] {
            Write-LogEntry -Message "Failed to remove Feature on Demand V2 package: $($_.Exception.Message)" -Severity 3 @LogEntryParams
        }
        $f++
    }
}
catch [System.Exception] {
    Write-LogEntry -Message "Failed attempting to list Feature on Demand V2 packages: $($_.Exception.Message)" -Severity 3 @LogEntryParams
}
# Complete

If($PSBoundParameters.ContainsKey('TestOnly') )
{
    Write-Output ""
    Write-Output "Script would have removed $($RemovedAppxCollection.count) user appx's:"
    Write-Output "---------------------------------------------------------------------------------------"
    $RemovedAppxCollection | ForEach-Object{'  ' + $_}

    Write-Output ""
    Write-Output "Script would have removed $($RemovedProvisionedAppxCollection.count) provisioned appx's:"
    Write-Output "---------------------------------------------------------------------------------------"
    $RemovedProvisionedAppxCollection | ForEach-Object{'  ' + $_}

    Write-Output ""
    Write-Output "Script would have removed $($RemovedFODCollection.count) Feature on Demand items:"
    Write-Output "---------------------------------------------------------------------------------------"
    $RemovedFODCollection | ForEach-Object{'  ' + $_}

    Write-Output "---------------------------------------------------------------------------------------"
    Write-Output ""
}

Write-LogEntry -Message "Completed built-in AppxPackage and AppxProvisioningPackage removal process" @LogEntryParams
