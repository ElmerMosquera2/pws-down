function pws {
    param(
        [switch]$activate,
        [switch]$disable,
        [switch]$minimal,
        [switch]$full,
        [switch]$update
    )
    
    $saveRequired = $false

    if ($activate) { $global:PwsConfig.Enabled = $true; $saveRequired = $true; Write-Host "✅ pws-down activado." -ForegroundColor Cyan }
    if ($disable) { $global:PwsConfig.Enabled = $false; $saveRequired = $true; Write-Host "🌑 pws-down desactivado." -ForegroundColor DarkGray }
    
    if ($minimal) { 
        $global:PwsConfig.Layout = @("Path", "Git")
        $saveRequired = $true
        Write-Host "🧹 Modo minimalista activado." -ForegroundColor Yellow 
    }
    if ($full) { 
        $global:PwsConfig.Layout = @("Time", "Duration", "Software", "Path", "Git")
        $saveRequired = $true
        Write-Host "✨ Modo completo activado." -ForegroundColor Yellow 
    }
    
    if ($update) {
        Write-Host "🔄 Escaneando Registro (Nativo)..." -ForegroundColor Cyan
        $pyPath = "HKCU:\Software\Python\PythonCore"
        if (Test-Path $pyPath) {
            $global:PwsConfig.SoftwareCache.Python = (Get-ChildItem $pyPath | Select-Object -ExpandProperty PSChildName -First 1)
            Write-Host "  ✅ Python detectado." -ForegroundColor Green
        }
        $saveRequired = $true
    }

    # Guardar en disco solo si hubo cambios
    if ($saveRequired) {
        $global:PwsConfig | ConvertTo-Json -Depth 3 | Out-File $global:PwsConfigFile -Encoding utf8
    }
}
