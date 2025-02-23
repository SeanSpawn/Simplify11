@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (
    echo Not running as admin. Elevating...
    where wt.exe >nul 2>&1
    if %errorlevel% equ 0 (
        powershell -Command "Start-Process -FilePath 'wt.exe' -ArgumentList 'cmd /k \"%~0\"' -Verb runAs"
    ) else (
        powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k \"%~0\"' -Verb runAs"
    )
    exit /b
)

set Purple=[38;5;141m
set Grey=[38;5;250m
set Reset=[0m
set Red=[38;5;203m
set Green=[38;5;120m

:freeUpSpace

echo.
echo %Grey%Would you like to disable Reserved Storage?%Reset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "storage_choice=%errorlevel%"
if !storage_choice!==1 (
    echo %Grey%Disabling Reserved Storage...%Reset%
    dism /Online /Set-ReservedStorageState /State:Disabled
)

echo.
echo %Grey%Would you like to clean up WinSxS?%Reset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "winsxs_choice=%errorlevel%"
if !winsxs_choice!==1 (
    echo %Grey%Cleaning up WinSxS...%Reset%
    dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /RestoreHealth
)

echo.
echo %Grey%Would you like to remove Virtual Memory (pagefile.sys)?%Reset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "vm_choice=%errorlevel%"
if !vm_choice!==1 (
    echo %Grey%Removing Virtual Memory...%Reset%
    powershell -Command "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value ''"
)

echo.
echo %Grey%Would you like to install and launch PC Manager? (Official Microsoft Utility from Store)%Reset%
choice /C 12 /N /M "[1] Yes or [2] No : "
set /a "pcmanager_choice=%errorlevel%"
if !pcmanager_choice!==1 (
    echo %Grey%Installing PC Manager...%Reset%
    winget install Microsoft.PCManager --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo Successfully installed PC Manager.
        timeout /t 2
        start "" "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
    ) else if !errorlevel! equ -1978335189 (
        echo %Grey%PC Manager is already installed. Launching...%Reset%
        start "" "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
    ) else (
        echo Failed to install PC Manager. Please try manually.
        start "" "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9pm860492szd&storecid=storeweb-pdp-open-cta"
        pause
    )
)

exit