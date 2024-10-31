enum Error {
    ADBNotFound
    PDANotFound
    APKNotFound
    DWNotFound
    ConfigNotFound
}

function Get-ADBPath {
    $adb_x86 = ${env:ProgramFiles(x86)} + '\Minimal ADB and Fastboot\'
    $adb_x64 = ${env:ProgramFiles} + '\Minimal ADB and Fastboot\'

    $assert_x86 = Test-Path -Path $adb_x86
    $assert_x64 = Test-Path -Path $adb_x64
    if($assert_x86) {
        return $adb_x86
    } elseif ($assert_x64) {
        return $adb_x64
    } else {
        return [Error]::ADBNotFound
    }
    
}

function Assert-DeviceConnection ($adb_path) {
    Set-Location $adb_path
    $device_list = .\adb.exe devices
    $connected_device = $device_list -Match '(\d{14})'
    if (-Not($connected_device)) {
        Set-Location $PSScriptRoot
        return [Error]::PDANotFound
    }
    Set-Location $PSScriptRoot
}

function Get-UserSetting($prompt) {
    $res = Read-Host $prompt
    Switch ($res) {
        'y' { return $true }
        'n' { return $false }
        default { Get-UserSetting($prompt) }
    }
}

function Update-ConfigFiles ($adb_path) {
    Set-Location $PSScriptRoot
    $config_files = Get-ChildItem -Path . -Filter *.json
    if ($config_files.Length -eq 0) {
        return [Error]::ConfigNotFound
    }

    Set-Location $adb_path 
    foreach ($config in $config_files) {
        $updating = $PSScriptRoot + '\' + $config.Name
        $result = .\adb.exe push $updating /sdcard
        if (-Not ($result -Match 'pushed.')) {
            '$! Failed To Update Config: ' + $config.Name
        } else {
            '$! Updated Config: ' + $config.Name
        }
    }
    Set-Location $PSScriptRoot
}

function Install-APKFiles ($adb_path) {
    Set-Location $PSScriptRoot
    $apk_files = Get-ChildItem -Path . -Filter *.apk
    if ($apk_files.Length -eq 0) {
        return [Error]::APKNotFound
    }

    Set-Location $adb_path 
    foreach ($apk in $apk_files) {
        $installing = $PSScriptRoot + '\' + $apk.Name
        $result = .\adb.exe install $installing
        if (-Not ($result -Match 'Success')) {
            '$! Failed To Install APK: ' + $apk.Name
        } else {
            '$! Installed APK: ' + $apk.Name
        }
    }
    Set-Location $PSScriptRoot
}

function Import-DataWedge ($adb_path) {
    $dw_files = Get-ChildItem -Path . -Filter *.db
    if ($dw_files.Length -eq 0) {
        return [Error]::DWNotFound
    }

    Set-Location $adb_path
    foreach ($dw_file in $dw_files) {
        $file = $PSScriptRoot + '\' + $dw_file.Name
        $result = .\adb.exe push $file /sdcard
        if (-Not ($result -Match 'pushed.')) {
            '$! Failed To Transfer File: ' + $dw_file.Name
        } else {
            '$! Transferred DataWedge file: ' + $dw_file.Name
        }
    }
    Set-Location $PSScriptRoot
}

function Write-PDALogger ($adb_path) {
    Set-Location $adb_path
    $device_string = .\adb.exe devices
    $device_id = $device_string -Match '(\d{14})'
    $device_name = Read-Host ('$! Friendly Name For HWID {0}' -f $device_id.Substring(0,14))
    $out = 'HWID: {0} - Description: TC26-{1}' -f $device_id.Substring(0,14), $device_name
    Set-Location $PSScriptRoot
    if (-Not (Test-Path -Path .\devices.txt)) {
        New-Item -Path . -Name 'devices.txt' -ItemType 'file' | Out-Null
    }
    Add-Content -Path .\devices.txt -Value $out | Out-Null
}


# Script Start
Set-Location $PSScriptRoot
$running = $true
$adb = Get-ADBPath

if ($adb -eq [Error]::ADBNotFound) {
    "$! ERROR: Unable To Find ADB Installation!"
    return
}

$pda_logging = Get-UserSetting('$! [Y/N] Enable HWID Logging')
$update_config = Get-UserSetting('$! [Y/N] Update Config Files')
$update_apk = Get-UserSetting('$! [Y/N] Update APK')
$update_datawedge = Get-UserSetting('$! [Y/N] Update DataWedge')
''
While ($running) {
    $device_status = Assert-DeviceConnection($adb)
    if ($device_status -eq [Error]::PDANotFound) {
        "$! ERROR: Unable To Find Connected Device!"
        return
    }
    if ($pda_logging) {
        Write-PDALogger($adb)
    }
    if ($update_config) {
        '$! --- Updating Config Files'
        $config_result = Update-ConfigFiles($adb)
        if ($config_result -eq [Error]::ConfigNotFound) {
            '$! WARNING: Update Config Files Is Enabled, But No Config Files Were Found'
        } else {
            $config_result
        }
    }
    if ($update_apk) {
        '$! --- Installing APK Files'
        $apk_result = Install-APKFiles($adb)
        if ($apk_result -eq [Error]::APKNotFound) {
            '$! WARNING: Update APK Is Enabled, But No APK Files Were Found'
        } else {
            $apk_result
        }
    }
    if ($update_datawedge) {
        '$! --- Transferring DataWedge file(s)'
        $dw_result = Import-DataWedge($adb)
        if ($dw_result -eq [Error]::DWNotFound) {
            '$! WARNING: Update DataWedge Is Enabled, But No DataWedge Files Were Found'
        } else {
            $dw_result
        }
    }
    '$! Device Update Finished!'
    ''
    $running = Get-UserSetting('$! [Y/N] Update New Device')
}

