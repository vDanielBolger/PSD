$verbosePreference = "Continue"


# Load core modules

Import-Module DISM

$deployRoot = Split-Path -Path "$PSScriptRoot"
Write-Verbose "Using deploy root $deployRoot, based on $PSScriptRoot"
Import-Module "$deployRoot\Scripts\PSDUtility.psm1" -Force
Import-Module "$deployRoot\Scripts\PSDProvider.psm1" -Force


# Make sure we run at full power

& powercfg.exe /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c


# Apply the OS

Write-Verbose "Operating system: $($tsenv:OSGUID)"
$os = Get-Item "DeploymentShare:\Operating Systems\$($tsenv:OSGUID)"
$image = "$($tsenv:Deployroot)\$($os.ImageFile.Substring(2))"
$index = $os.ImageIndex

$scratchPath = "$(Get-PSDLocalDataPath)\Scratch"
Initialize-PSDFolder $scratchPath
Write-Verbose "Applying image $image index $index to $($tsenv:OSVolume)"
$startTime = Get-Date
Expand-WindowsImage -ImagePath $image -Index $index -ApplyPath "$($tsenv:OSVolume):\" -ScratchDirectory $scratchPath
$duration = $(Get-Date) - $startTime
Write-Verbose "Time to apply image: $($duration.ToString('hh\:mm\:ss'))"


# Make the OS bootable

Write-Verbose "Configuring volume $($tsenv:BootVolume) to boot $($tsenv:OSVolume):\Windows."

if ($tsenv:IsUEFI -eq "True")
{
    $args = @("$($tsenv:OSVolume):\Windows", "/s", "$($tsenv:BootVolume):", "/f", "uefi")
}
else 
{
    $args = @("$($tsenv:OSVolume):\Windows", "/s", "$($tsenv:BootVolume):")
}
$args
$result = Start-Process -FilePath "bcdboot.exe" -ArgumentList $args -Wait -Passthru
Write-Verbose "BCDBoot completed, rc = $($result.ExitCode)"
