. "$PSScriptRoot\..\..\scripts\Common.ps1"
# https://github.com/SysadminWorld/Win11Tweaks
# https://github.com/AlchemyTweaks/Verified-Tweaks
# https://github.com/SanGraphic/QuickBoost

# https://github.com/UnLovedCookie/CoutX
# https://github.com/Snowfliger/SyncOS
# https://github.com/denis-g/windows10-latency-optimization

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as admin. Elevating..." -ForegroundColor Yellow
    . "$PSScriptRoot\..\..\scripts\AdminLaunch.ps1"
    Start-AdminProcess -ScriptPath $PSCommandPath
    exit
}

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Type,
        $Value,
        [string]$Message
    )
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force
        Write-Host "$Green[SUCCESS]$Reset $Message"
    }
    catch {
        Write-Host "$Red[FAILED]$Reset Failed to set $Name at $Path"
        Write-Host "Error: $_"
    }
}

function Show-MainMenu {
    $Host.UI.RawUI.WindowTitle = "Simplify11 - System Tweaks"
    Clear-Host
    Write-Host ""
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple |$Reset [1] Universal Tweaks                $Purple|$Reset"
    Write-Host "$Purple |$Reset [2] Free Up Space                   $Purple|$Reset"
    Write-Host "$Purple |$Reset [3] NVIDIA/AMD GPU Tweaks           $Purple|$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple |$Reset [4] Back to menu                    $Purple|$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    
    do {
        $choice = Read-Host "Enter your choice (1-4)"
    } while ($choice -notmatch '^[1-4]$')
    
    switch ($choice) {
        "1" { Apply-UniversalTweaks }
        "2" { FreeUpSpace }
        "3" { Show-GPUMenu }
        "4" { & "$PSScriptRoot\..\..\simplify11.ps1" }
        default { Show-MainMenu }
    }
}

function Apply-UniversalTweaks {
    Apply-SystemLatencyTweaks
    Apply-InputDeviceTweaks
    Apply-SSDTweaks
    Apply-GPUTweaks
    Apply-NetworkTweaks
    Apply-CPUTweaks
    Apply-PowerTweaks
    Apply-SystemResponsivenessTweaks
    Apply-BootOptimizationTweaks
    Apply-SystemMaintenanceTweaks
    Apply-UIResponsivenessTweaks
    Apply-MemoryTweaks
    Apply-DirectXTweaks
    
    Write-Host "`n$Purple Press any key to return to the main menu...$Reset"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-MainMenu
}

function Apply-SystemLatencyTweaks {
    Write-Host "`nApplying System Latency tweaks...`n"
    
    # System Latency Tweaks
    # Changing Interrupts behavior for lower latency
    # source - https://youtu.be/Gazv0q3njYU
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "InterruptSteeringDisabled" -Type "DWord" -Value "1" -Message "Disabled interrupt steering for lower latency"
    
    # Serialize Timer Expiration mechanism, officially documented in Windows Internals 7th E2
    # Improves system timing and interrupt handling
    # source - https://youtu.be/wil-09_5H0M
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "SerializeTimerExpiration" -Type "DWord" -Value "1" -Message "Enabled timer serialization for better system timing"
}

function Apply-InputDeviceTweaks {
    Write-Host "`nApplying Input Device tweaks...`n"
    
    # Mouse & Keyboard Tweaks
    # The MouseDataQueueSize and KeyboardDataQueueSize parameters set the number of events stored in the mouse and keyboard driver buffers
    # A smaller value means faster processing of new information
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Type "DWord" -Value "20" -Message "Optimized mouse input buffer size"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Type "DWord" -Value "20" -Message "Optimized keyboard input buffer size"

    # Accessibility and keyboard response settings
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility" -Name "StickyKeys" -Type "String" -Value "506" -Message "Disabled StickyKeys for better gaming experience"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Type "String" -Value "58" -Message "Modified ToggleKeys behavior"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "DelayBeforeAcceptance" -Type "String" -Value "0" -Message "Removed keyboard input delay"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatRate" -Type "String" -Value "0" -Message "Optimized key repeat rate"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatDelay" -Type "String" -Value "0" -Message "Removed key repeat delay"
    Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Type "String" -Value "122" -Message "Modified keyboard response flags"
}

function Apply-SSDTweaks {
    Write-Host "`nApplying SSD/NVMe tweaks...`n"
    
    # Check if SSD/NVMe exists
    $hasSSD = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' -or $_.BusType -eq 'NVMe' } | Measure-Object | Select-Object -ExpandProperty Count
    if ($hasSSD -gt 0) {
        
        Write-Host "Enable and optimize TRIM for SSD"
        fsutil behavior set DisableDeleteNotify 0
    
        Write-Host "Disable defragmentation for SSDs"
        Disable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag"
        
        Write-Host "Disable NTFS last access time updates"
        fsutil behavior set disablelastaccess 1
        
        Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisable8dot3NameCreation" -Type "DWord" -Value "1" -Message "Disabled legacy 8.3 filename creation for better SSD performance"
       
        # Disable ApplicationPreLaunch & Prefetch
        # These services analyze apps in the background and cache data to speed up launches
        # On an SSD, apps load fast without them, so caching isn't needed
        Disable-MMAgent -ApplicationPreLaunch
        
        Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Type "DWord" -Value "0" -Message "Disabled prefetcher for better SSD performance"
        Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "SfTracingState" -Type "DWord" -Value "0" -Message "Disabled superfetch tracing"
    } else {
        Write-Host "No SSD or NVMe detected. Skipping tweaks."
    }
}

function Apply-GPUTweaks {
    Write-Host "`nApplying GPU Performance tweaks...`n"
    
    # GPU Performance Tweaks
    # The HwSchMode parameter optimizes hardware-level computation scheduling (Hardware Accelerated GPU Scheduling), reducing latency on lower-end GPUs.
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Type "DWord" -Value "2" -Message "Optimized GPU hardware scheduling"
    Set-RegistryValue -Path "HKLM:\SYSTEM\ControlSet001\Control\GraphicsDrivers\Scheduler" -Name "EnablePreemption" -Type "DWord" -Value "0" -Message "Disabled GPU preemption for better performance"
}

function Apply-NetworkTweaks {
    Write-Host "`nApplying Network tweaks...`n"
    
    # Network Optimization
    # By default, Windows uses network throttling to limit non-multimedia traffic to 10 packets per millisecond (about 100 Mb/s).
    # This is to prioritize CPU access for multimedia applications, as processing network packets can be resource-intensive.
    # However, it's recommended to disable this setting, especially with gigabit networks, to avoid unnecessary interference.
    # source - https://youtu.be/EmdosMT5TtA
    
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type "DWord" -Value "4294967295" -Message "Disabled network throttling for maximum network performance"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NoLazyMode" -Type "DWord" -Value "1" -Message "Disabled lazy mode for network operations"
}

function Apply-CPUTweaks {
    Write-Host "`nApplying CPU Performance tweaks...`n"
    
    # CPU Tweaks
    # LazyMode is a software flag that allows the system to skip some hardware events when CPU load is low.
    # Disabling it can use more resources for event processing, so we set the timer to a minimum of 1ms (10000ms).
    # source - https://youtu.be/FxpRL7wheGc
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "LazyModeTimeout" -Type "DWord" -Value "25000" -Message "Set optimal lazy mode timeout for better CPU responsiveness"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MMCSS" -Name "Start" -Type "DWord" -Value "2" -Message "Configured Multimedia Class Scheduler Service for better performance"
}

function Apply-PowerTweaks {
    Write-Host "`nApplying Power Management tweaks...`n"
    
    # Power Management Tweaks
    # Power Throttling is a service that slows down background apps to save energy on laptops.
    # In this case, it's unnecessary, so it's recommended to disable it.
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Type "DWord" -Value "1" -Message "Disabled power throttling for maximum performance"

    # source - https://github.com/ancel1x/Ancels-Performance-Batch
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Type "DWord" -Value "0" -Message "Disabled AC/DC platform power behavior override"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "EnergyEstimationEnabled" -Type "DWord" -Value "0" -Message "Disabled energy estimation for better performance"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "EventProcessorEnabled" -Type "DWord" -Value "0" -Message "Disabled power event processor"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "CsEnabled" -Type "DWord" -Value "0" -Message "Disabled connected standby for better performance"

    # Activate Hidden Ultimate Performance Power Plan
    Write-Host "Activating Ultimate Performance Power Plan"
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
    powercfg -setactive eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
}

function Apply-SystemResponsivenessTweaks {
    Write-Host "`nApplying System Responsiveness tweaks...`n"
    
    # Set Priority For Programs Instead Of Background Services
    # This improves responsiveness of foreground applications
    # source - https://youtu.be/bqDMG1ZS-Yw
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Type "DWord" -Value "0x00000024" -Message "Optimized process priority for better responsiveness"
    Set-RegistryValue -Path "HKLM:\SYSTEM\ControlSet001\Control\PriorityControl" -Name "IRQ8Priority" -Type "DWord" -Value "1" -Message "Set IRQ8 priority for better system response"
    Set-RegistryValue -Path "HKLM:\SYSTEM\ControlSet001\Control\PriorityControl" -Name "IRQ16Priority" -Type "DWord" -Value "2" -Message "Set IRQ16 priority for better system response"
}

function Apply-BootOptimizationTweaks {
    Write-Host "`nApplying Boot Optimization tweaks...`n"
    
    # Boot System & Software without limits
    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "Startupdelayinmsec" -Type "DWord" -Value "0" -Message "Removed startup delay for faster boot"
    
    # Speed up start time
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DelayedDesktopSwitchTimeout" -Type "DWord" -Value "0" -Message "Removed desktop switch delay"
}

function Apply-SystemMaintenanceTweaks {
    Write-Host "`nApplying System Maintenance tweaks...`n"
    
    # Disable Automatic maintenance
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" -Name "MaintenanceDisabled" -Type "DWord" -Value "1" -Message "Disabled automatic maintenance for better performance"
}

function Apply-UIResponsivenessTweaks {
    Write-Host "`nApplying UI Responsiveness tweaks...`n"
    
    # UI Responsiveness Tweaks
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Type "String" -Value "1" -Message "Enabled automatic ending of tasks"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Type "String" -Value "1000" -Message "Reduced hung application timeout"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Type "String" -Value "2000" -Message "Reduced wait time for killing applications"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "LowLevelHooksTimeout" -Type "String" -Value "1000" -Message "Reduced low level hooks timeout"
    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type "String" -Value "0" -Message "Removed menu show delay"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type "String" -Value "2000" -Message "Reduced wait time for killing services"
}

function Apply-MemoryTweaks {
    Write-Host "`nApplying Memory Optimization tweaks...`n"
    
    # Memory Tweaks
    # source - https://github.com/SanGraphic/QuickBoost/blob/main/v2/MemoryTweaks.bat
    
    # Enabling Large System Cache makes the OS use all RAM for caching system files,
    # except 4MB reserved for disk cache, improving Windows responsiveness.
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Type "DWord" -Value "1" -Message "Enabled large system cache for better performance"
    
    # Disabling Windows attempt to save as much RAM as possible, such as sharing pages for images, copy-on-write for data pages, and compression
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingCombining" -Type "DWord" -Value "1" -Message "Disabled memory page combining"
    
    # Enabling this parameter keeps the system kernel and drivers in RAM instead of the page file, improving responsiveness.
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Type "DWord" -Value "1" -Message "Disabled paging of kernel and drivers"
}

function Apply-DirectXTweaks {
    Write-Host "`nApplying DirectX tweaks...`n"
    
    # DirectX Optimizations
    # source - https://youtu.be/itTcqcJxtbo
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ENABLE_UNSAFE_COMMAND_BUFFER_REUSE" -Type "DWord" -Value "1" -Message "Enabled D3D12 command buffer reuse"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ENABLE_RUNTIME_DRIVER_OPTIMIZATIONS" -Type "DWord" -Value "1" -Message "Enabled D3D12 runtime optimizations"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_RESOURCE_ALIGNMENT" -Type "DWord" -Value "1" -Message "Optimized D3D12 resource alignment"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_MULTITHREADED" -Type "DWord" -Value "1" -Message "Enabled D3D11 multithreading"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_MULTITHREADED" -Type "DWord" -Value "1" -Message "Enabled D3D12 multithreading"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_DEFERRED_CONTEXTS" -Type "DWord" -Value "1" -Message "Enabled D3D11 deferred contexts"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_DEFERRED_CONTEXTS" -Type "DWord" -Value "1" -Message "Enabled D3D12 deferred contexts"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_ALLOW_TILING" -Type "DWord" -Value "1" -Message "Enabled D3D11 tiling optimization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D11_ENABLE_DYNAMIC_CODEGEN" -Type "DWord" -Value "1" -Message "Enabled D3D11 dynamic code generation"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_ALLOW_TILING" -Type "DWord" -Value "1" -Message "Enabled D3D12 tiling optimization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_CPU_PAGE_TABLE_ENABLED" -Type "DWord" -Value "1" -Message "Enabled D3D12 CPU page table"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_HEAP_SERIALIZATION_ENABLED" -Type "DWord" -Value "1" -Message "Enabled D3D12 heap serialization"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_MAP_HEAP_ALLOCATIONS" -Type "DWord" -Value "1" -Message "Enabled D3D12 heap allocation mapping"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "D3D12_RESIDENCY_MANAGEMENT_ENABLED" -Type "DWord" -Value "1" -Message "Enabled D3D12 residency management"
}


function FreeUpSpace {
    $host.UI.RawUI.WindowTitle = "System Cleaner"
    Write-Host ""
    Write-Host "$Reset`Would you like to disable Reserved Storage?$Reset"
    Write-Host "$Yellow`This can free up to 7GB of space used for Windows updates.$Reset"
    $storage_choice = Read-Host "[1] Yes or [2] No"
    if ($storage_choice -eq "1") {
        Write-Host "$Reset`Disabling Reserved Storage...$Reset"
        Invoke-Expression "dism /Online /Set-ReservedStorageState /State:Disabled"
    }

    Write-Host ""
    Write-Host "$Reset`Would you like to clean up WinSxS?$Reset"
    Write-Host "$Yellow`This removes old component versions and reduces the size of the WinSxS folder.$Reset"
    $winsxs_choice = Read-Host "[1] Yes or [2] No"
    if ($winsxs_choice -eq "1") {
        Write-Host "$Reset`Cleaning up WinSxS...$Reset"
        Invoke-Expression "dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /RestoreHealth"
    }

    Write-Host ""
    Write-Host "$Reset`Would you like to remove Virtual Memory (pagefile.sys)?$Reset"
    Write-Host "$Yellow`Warning: This may affect system performance. Only use if you have 16GB+ RAM.$Reset"
    $vm_choice = Read-Host "[1] Yes or [2] No"
    if ($vm_choice -eq "1") {
        Write-Host "$Reset`Removing Virtual Memory...$Reset"
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value ''
    }

    Write-Host ""
    Write-Host "$Reset`Would you like to install and launch PC Manager? (Official Microsoft Utility from Store)$Reset"
    $pcmanager_choice = Read-Host "[1] Yes or [2] No"
    if ($pcmanager_choice -eq "1") {
        Write-Host "$Reset`Installing PC Manager...$Reset"
        $result = Invoke-Expression "winget install Microsoft.PCManager --accept-package-agreements --accept-source-agreements"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully installed PC Manager."
            Start-Sleep -Seconds 2
            Start-Process "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Host "$Reset`PC Manager is already installed. Launching...$Reset"
            Start-Process "shell:AppsFolder\Microsoft.MicrosoftPCManager_8wekyb3d8bbwe!App"
        } else {
            Write-Host "Failed to install PC Manager. Please try manually."
            Start-Process "ms-windows-store://pdp?hl=en-us&gl=us&ocid=pdpshare&referrer=storeforweb&productid=9pm860492szd&storecid=storeweb-pdp-open-cta"
            Read-Host "Press Enter to continue..."
        }
    }

    Write-Host ""
    Write-Host "$Green`All selected cleaning operations completed.$Reset"
    Show-MainMenu
}

function Show-GPUMenu {
    Clear-Host
    Write-Host ""
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple |$Reset Select your GPU manufacturer:       $Purple|$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple |$Reset [1] NVIDIA                          $Purple|$Reset"
    Write-Host "$Purple |$Reset [2] AMD                             $Purple|$Reset"
    Write-Host "$Purple |$Reset [3] Both (Hybrid Laptop)            $Purple|$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    Write-Host "$Purple |$Reset [4] Back to Main Menu               $Purple|$Reset"
    Write-Host "$Purple +-------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { Apply-NvidiaTweaks }
        "2" { Apply-AMDTweaks }
        "3" { Apply-HybridTweaks }
        "4" { Show-MainMenu }
        default { Show-GPUMenu }
    }
}

function Apply-HybridTweaks {
    Write-Host "$Green Applying tweaks for hybrid GPU configuration (NVIDIA + AMD)...$Reset"
    Apply-NvidiaTweaks -NoExit
    Apply-AMDTweaks -NoExit
    Write-Host "$Green Successfully applied tweaks for both NVIDIA and AMD GPUs.$Reset"
    Write-Host ""
    Write-Host "$Purple Press any key to return to the GPU menu...$Reset"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-GPUMenu
}

function Apply-NvidiaTweaks {
    param (
        [switch]$NoExit
    )
    
    # source - https://github.com/AlchemyTweaks/Verified-Tweaks/blob/main/Nvidia/RmGpsPsEnablePerCpuCoreDpc
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled per-CPU core DPC for NVIDIA drivers"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled power-aware per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled NVIDIA driver per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\NVAPI" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled NVIDIA API per-CPU core DPC"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" -Name "RmGpsPsEnablePerCpuCoreDpc" -Type "DWord" -Value "1" -Message "Enabled global NVIDIA tweaks for per-CPU core DPC"
    
if (-not $NoExit) {
        Write-Host ""
        Write-Host "$Purple Press any key to return to the GPU menu...$Reset"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
       Show-GPUMenu
    }
}

function Apply-AMDTweaks {
    param (
        [switch]$NoExit
    )
    
    # source - https://youtu.be/nuUV2RoPOWc , https://github.com/AlchemyTweaks/Verified-Tweaks/blob/main/AMD%20Radeon/AMD%20Tweak%20Melody
    $amdPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
    Set-RegistryValue -Path $amdPath -Name "AllowSnapshot" -Type "DWord" -Value "0" -Message "Disabled AMD snapshot feature"
    Set-RegistryValue -Path $amdPath -Name "AllowSubscription" -Type "DWord" -Value "0" -Message "Disabled AMD subscription feature"
    Set-RegistryValue -Path $amdPath -Name "AllowRSOverlay" -Type "String" -Value "false" -Message "Disabled AMD RS overlay"
    Set-RegistryValue -Path $amdPath -Name "AllowSkins" -Type "String" -Value "false" -Message "Disabled AMD skins"
    Set-RegistryValue -Path $amdPath -Name "AutoColorDepthReduction_NA" -Type "DWord" -Value "0" -Message "Disabled automatic color depth reduction"
    Set-RegistryValue -Path $amdPath -Name "DisableUVDPowerGatingDynamic" -Type "DWord" -Value "1" -Message "Disabled UVD power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableVCEPowerGating" -Type "DWord" -Value "1" -Message "Disabled VCE power gating"
    Set-RegistryValue -Path $amdPath -Name "DisablePowerGating" -Type "DWord" -Value "1" -Message "Disabled general power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableDrmdmaPowerGating" -Type "DWord" -Value "1" -Message "Disabled DRMDMA power gating"
    Set-RegistryValue -Path $amdPath -Name "DisableDMACopy" -Type "DWord" -Value "1" -Message "Disabled DMA copy"
    Set-RegistryValue -Path $amdPath -Name "DisableBlockWrite" -Type "DWord" -Value "0" -Message "Enabled block write"
    Set-RegistryValue -Path $amdPath -Name "StutterMode" -Type "DWord" -Value "0" -Message "Disabled stutter mode"
    Set-RegistryValue -Path $amdPath -Name "PP_GPUPowerDownEnabled" -Type "DWord" -Value "0" -Message "Disabled GPU power down"
    Set-RegistryValue -Path $amdPath -Name "LTRSnoopL1Latency" -Type "DWord" -Value "1" -Message "Optimized LTR Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRSnoopL0Latency" -Type "DWord" -Value "1" -Message "Optimized LTR Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRNoSnoopL1Latency" -Type "DWord" -Value "1" -Message "Optimized LTR No Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "LTRMaxNoSnoopLatency" -Type "DWord" -Value "1" -Message "Optimized LTR max no snoop latency"
    Set-RegistryValue -Path $amdPath -Name "KMD_RpmComputeLatency" -Type "DWord" -Value "1" -Message "Optimized KMD RPM compute latency"
    Set-RegistryValue -Path $amdPath -Name "DalUrgentLatencyNs" -Type "DWord" -Value "1" -Message "Optimized DAL urgent latency"
    Set-RegistryValue -Path $amdPath -Name "memClockSwitchLatency" -Type "DWord" -Value "1" -Message "Optimized memory clock switch latency"
    Set-RegistryValue -Path $amdPath -Name "PP_RTPMComputeF1Latency" -Type "DWord" -Value "1" -Message "Optimized RTPM compute F1 latency"
    Set-RegistryValue -Path $amdPath -Name "PP_DGBMMMaxTransitionLatencyUvd" -Type "DWord" -Value "1" -Message "Optimized DGBMM UVD transition latency"
    Set-RegistryValue -Path $amdPath -Name "PP_DGBPMMaxTransitionLatencyGfx" -Type "DWord" -Value "1" -Message "Optimized DGBPM GFX transition latency"
    Set-RegistryValue -Path $amdPath -Name "DalNBLatencyForUnderFlow" -Type "DWord" -Value "1" -Message "Optimized DAL NB underflow latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRSnoopL1Latency" -Type "DWord" -Value "1" -Message "Optimized BGM LTR Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRSnoopL0Latency" -Type "DWord" -Value "1" -Message "Optimized BGM LTR Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRNoSnoopL1Latency" -Type "DWord" -Value "1" -Message "Optimized BGM LTR No Snoop L1 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRNoSnoopL0Latency" -Type "DWord" -Value "1" -Message "Optimized BGM LTR No Snoop L0 latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRMaxSnoopLatencyValue" -Type "DWord" -Value "1" -Message "Optimized BGM LTR max snoop latency"
    Set-RegistryValue -Path $amdPath -Name "BGM_LTRMaxNoSnoopLatencyValue" -Type "DWord" -Value "1" -Message "Optimized BGM LTR max no snoop latency"
    
    if (-not $NoExit) {
        Write-Host ""
        Write-Host "$Purple Press any key to return to the GPU menu...$Reset"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Show-GPUMenu
    }
}

Show-MainMenu