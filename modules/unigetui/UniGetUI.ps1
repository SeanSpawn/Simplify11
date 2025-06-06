. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - UniGetUI"
    Clear-Host
    Write-Host "$Purple +------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset UniGetUI (formerly WingetUI)             $Purple'$Reset"
    Write-Host "$Purple +------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Install and Launch                   $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Open List of Apps by Category        $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Try Fixing Winget if something wrong $Purple'$Reset"
    Write-Host "$Purple +------------------------------------------+$Reset"
    
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" { Install-UniGetUI }
        "2" { Show-AppCategoryMenu }
        "3" { Check-Winget }
        default { Show-MainMenu }
    }
}

function Install-UniGetUI {
    Clear-Host
    Write-Host "$Purple +---                    ---+$Reset"
    Write-Host "$Purple  '$Reset    Install UniGetUI    $Purple'$Reset"
    Write-Host "$Purple +---                    ---+$Reset"

    & winget source update
    
    $isInstalled = & winget list --id MartiCliment.UniGetUI --accept-source-agreements | Select-String "MartiCliment.UniGetUI"
    
    if ($isInstalled) {
        Write-Host "$Reset UniGetUI is already installed. Launching...$Reset"
        Start-Process "unigetui:"
    } else {
        Write-Host "$Reset Installing UniGetUI...$Reset"
        $result = & winget install MartiCliment.UniGetUI --accept-package-agreements --accept-source-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$Green Successfully installed UniGetUI.$Reset"
            Start-Process "unigetui:"
        } else {
            Write-Host "$Red Failed to install UniGetUI. Opening website for manual download...$Reset"
            Start-Process "https://www.marticliment.com/unigetui/"
            Check-Winget
        }
    }
    
    Show-MainMenu
}

function Check-Winget {
    $wingetExists = Get-Command winget -ErrorAction SilentlyContinue
    
    if (-not $wingetExists) {
        Write-Host "$Red Winget is not installed. Please install Windows App Installer from Microsoft Store.$Reset"
        Start-Process "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
        Read-Host "Press Enter to continue"
    }
    
    Show-MainMenu
}

function Show-AppCategoryMenu {
    Clear-Host
    Write-Host "$Purple +--------------------------------+$Reset"
    Write-Host "$Purple '$Reset App Categories                 $Purple'$Reset"
    Write-Host "$Purple +--------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Development                $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Web Browsers               $Purple'$Reset"
    Write-Host "$Purple '$Reset [3] Utilities, Microsoft tools $Purple'$Reset"
    Write-Host "$Purple '$Reset [4] Productivity Suite         $Purple'$Reset"
    Write-Host "$Purple '$Reset [5] Gaming Essentials          $Purple'$Reset"
    Write-Host "$Purple '$Reset [6] Communications             $Purple'$Reset"
    Write-Host "$Purple +--------------------------------+$Reset"
    
    $choice = Read-Host "Select a category"
    
    $bundleName = switch ($choice) {
        "1" { "development" }
        "2" { "browsers" }
        "3" { "utilities" }
        "4" { "productivity" }
        "5" { "games" }
        "6" { "communications" }
        default { Show-AppCategoryMenu; return }
    }
    
    # Fix for getting the script path reliably
    $scriptPath = if ($PSScriptRoot) {
        $PSScriptRoot
    } elseif ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $PWD.Path
    }
    
    $bundlePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "unigetui\ubundle\$bundleName.ubundle"
    
    Write-Host "Opening bundle: $bundlePath"
    
    try {
        Start-Process "$env:LOCALAPPDATA\Programs\UniGetUI\UniGetUI.exe" -ArgumentList "/launch", "`"$bundlePath`"" -ErrorAction Stop
        Read-Host "Press Enter to continue"
    }
    catch {
        try {
            Start-Process $bundlePath -ErrorAction Stop
        }
        catch {
            Write-Host "Make sure that you installed UniGetUI."
            Install-UniGetUI
            return
        }
    }
    
    Show-AppCategoryMenu
}

Show-MainMenu