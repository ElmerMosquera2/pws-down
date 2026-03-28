# ==========================================
# INICIALIZACIÓN DE PWS-DOWN (Windows 10/11)
# ==========================================
$global:PwsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:PwsConfigFile = Join-Path $global:PwsRoot "config\settings.json"

# 1. Cargar configuración JSON (con validación rápida)
if (Test-Path $global:PwsConfigFile -PathType Leaf) {
    $global:PwsConfig = Get-Content $global:PwsConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    Write-Warning "pws-down: No se encontró settings.json."
    return
}

# 2. Cargar Módulos (dot-sourcing optimizado)
foreach ($module in Get-ChildItem (Join-Path $global:PwsRoot "modules\*.ps1") -ErrorAction SilentlyContinue) {
    . $module.FullName
}

# ---------------------------------------------------------
# 3. CONTROLADOR INTEGRADO
# ---------------------------------------------------------
function pws {
    param(
        [switch]$activate, 
        [switch]$disable, 
        [switch]$minimal, 
        [switch]$full, 
        [switch]$update,
        [switch]$reload  # Nuevo: recargar módulos sin reiniciar
    )
    
    $saveRequired = $false
    $rebuildPlan = $false

    if ($activate) { 
        $global:PwsConfig.Enabled = $true
        $saveRequired = $true
        Write-Host "✅ pws-down activado." -ForegroundColor Cyan 
    }
    
    if ($disable) { 
        $global:PwsConfig.Enabled = $false
        $saveRequired = $true
        Write-Host "🌑 pws-down desactivado." -ForegroundColor DarkGray 
    }
    
    if ($minimal) { 
        $global:PwsConfig.Layout = @("Path", "Git")
        $saveRequired = $true
        $rebuildPlan = $true
        Write-Host "🧹 Modo minimalista activado." -ForegroundColor Yellow 
    }
    
    if ($full) { 
        $global:PwsConfig.Layout = @("Time", "Duration", "Software", "Path", "Git")
        $saveRequired = $true
        $rebuildPlan = $true
        Write-Host "✨ Modo completo activado." -ForegroundColor Yellow 
    }
    
    if ($update) {
        Write-Host "🔄 Escaneando Registro (Nativo)..." -ForegroundColor Cyan
        $pyPath = "HKCU:\Software\Python\PythonCore"
        if (Test-Path $pyPath) {
            $global:PwsConfig.SoftwareCache.Python = (Get-ChildItem $pyPath | Select-Object -First 1 -ExpandProperty PSChildName)
            Write-Host "  ✅ Python detectado." -ForegroundColor Green
        }
        $saveRequired = $true
    }
    
    if ($reload) {
        Write-Host "🔄 Recargando módulos..." -ForegroundColor Cyan
        Get-ChildItem (Join-Path $global:PwsRoot "modules\*.ps1") -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
        $rebuildPlan = $true
        Write-Host "  ✅ Módulos recargados." -ForegroundColor Green
    }

    if ($rebuildPlan) { 
        Update-PwsExecutionPlan 
    }
    
    if ($saveRequired) { 
        $global:PwsConfig | ConvertTo-Json -Depth 3 | Out-File $global:PwsConfigFile -Encoding utf8
    }
}

# ---------------------------------------------------------
# 4. COMPILADOR DEL PLAN DE EJECUCIÓN
# ---------------------------------------------------------
function Update-PwsExecutionPlan {
    $global:PwsExecutionPlan = [System.Collections.Generic.List[scriptblock]]::new()
    
    foreach ($moduleName in $global:PwsConfig.Layout) {
        $functionName = "Get-Pws$moduleName"
        $func = Get-Command -Name $functionName -ErrorAction SilentlyContinue
        if ($func) {
            $global:PwsExecutionPlan.Add($func.ScriptBlock)
        }
    }
}

# Compilación inicial
Update-PwsExecutionPlan

# ---------------------------------------------------------
# 5. EL PROMPT (Bucle Principal)
# ---------------------------------------------------------
function prompt {
    $lastCommandSuccess = $?
    $e = [char]27
    $promptString = ""

    if ($global:PwsConfig.Enabled -and $global:PwsExecutionPlan.Count -gt 0) {
        # Ejecución directa desde el plan en memoria
        foreach ($func in $global:PwsExecutionPlan) {
            $result = & $func
            if ($result) { $promptString += $result }
        }
    } elseif (-not $global:PwsConfig.Enabled) {
        # Prompt de respaldo (ultra-ligero)
        $promptString = "$e[90m[$([DateTime]::Now.ToString('HH:mm:ss'))]$e[0m $e[96m$($PWD.ProviderPath)$e[0m "
    }

    # Indicador final
    $indicatorStr = if ($lastCommandSuccess) { 
        "$e[95m$($global:PwsConfig.Symbols.indicator)$e[0m" 
    } else { 
        "$e[91m$($global:PwsConfig.Symbols.error)$e[0m" 
    }
    
    return "$promptString`n$indicatorStr "
}