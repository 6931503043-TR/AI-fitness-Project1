# Run from the project root (the folder that contains pubspec.yaml):
#   powershell -ExecutionPolicy Bypass -File .\setup_android.ps1
# This script is ASCII-only on purpose: Windows PowerShell 5.1 misreads
# non-ASCII characters in .ps1 files that have no BOM.
# What it does: adds the CAMERA permission and sets minSdk = 24 (required by ML Kit).

$ErrorActionPreference = "Stop"

$manifest = "android\app\src\main\AndroidManifest.xml"
if (-not (Test-Path $manifest)) { throw "Cannot find $manifest - are you in the project root?" }
$m = Get-Content $manifest -Raw
if ($m -notmatch "android.permission.CAMERA") {
    $m = $m -replace "(<manifest[^>]*>)", "`$1`n    <uses-permission android:name=`"android.permission.CAMERA`"/>"
    Set-Content $manifest $m -NoNewline
    Write-Host "Camera permission added"
} else {
    Write-Host "Camera permission already present"
}

$changed = $false
foreach ($f in @("android\app\build.gradle.kts", "android\app\build.gradle")) {
    if (Test-Path $f) {
        $g = Get-Content $f -Raw
        $new = $g -replace "minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 24"
        $new = $new -replace "minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 24"
        if ($new -ne $g) {
            Set-Content $f $new -NoNewline
            Write-Host "minSdk set to 24 in $f"
            $changed = $true
        }
    }
}
if (-not $changed) {
    Write-Host "No minSdk line needed changing. Open android\app\build.gradle(.kts) and confirm minSdk is 24 or higher."
}
