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

set cMauve=[38;5;141m
set cGrey=[38;5;250m
set cReset=[0m
set cRed=[38;5;203m
set cGreen=[38;5;120m

cls
echo.
echo %cMauve% +-----------------------------------+%cReset%
echo %cMauve% '%cGrey% Launching Windows Utility Tool... %cMauve%'%cReset%
echo %cMauve% +-----------------------------------+%cReset%

wt.exe cmd /c powershell -Command "irm 'https://christitus.com/win' | iex"
if %errorlevel% neq 0 (
    powershell -Command "irm 'https://christitus.com/win' | iex"
)
exit