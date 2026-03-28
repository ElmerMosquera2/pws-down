# ==========================================
# INICIALIZACIÓN DE PWS-DOWN (Ultra-Fast)
# ==========================================
$global:PwsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:PwsConfigFile = Join-Path $global:PwsRoot "config\settings.json"

# 1. Cargar configuración JSON en memoria
if (Test-Path $global:PwsConfigFile) {
    $global:PwsConfig = Get-Content $global:PwsConfigFile -Raw | ConvertFrom-Json
} else {
    Write-Warning "pws-down: No se encontró settings.json."
    return
}

# 2. Cargar Módulos de la carpeta (Dot-Sourcing)
Get-ChildItem (Join-Path $global:PwsRoot "modules\*.ps1") | ForEach-Object { . $_.FullName }

# ---------------------------------------------------------
# 3. CONTROLADOR INTEGRADO (El comando 'pws')
# ---------------------------------------------------------
function pws {
    param(
        [switch]$activate, [switch]$disable, 
        [switch]$minimal, [switch]$full, [switch]$update
    )
    
    $saveRequired = $false
    $rebuildPlan = $false

    if ($activate) { $global:PwsConfig.Enabled = $true; $saveRequired = $true; Write-Host "✅ pws-down activado." -ForegroundColor Cyan }
    if ($disable) { $global:PwsConfig.Enabled = $false; $saveRequired = $true; Write-Host "🌑 pws-down desactivado." -ForegroundColor DarkGray }
    
    if ($minimal) { 
        $global:PwsConfig.Layout = @("Path", "Git")
        $saveRequired = $true; $rebuildPlan = $true
        Write-Host "🧹 Modo minimalista activado." -ForegroundColor Yellow 
    }
    if ($full) { 
        $global:PwsConfig.Layout = @("Time", "Duration", "Software", "Path", "Git")
        $saveRequired = $true; $rebuildPlan = $true
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

    if ($rebuildPlan) { Update-PwsExecutionPlan }
    if ($saveRequired) { $global:PwsConfig | ConvertTo-Json -Depth 3 | Out-File $global:PwsConfigFile -Encoding utf8 }
}

# ---------------------------------------------------------
# 4. COMPILADOR DEL PLAN DE EJECUCIÓN (Para Latencia Cero)
# ---------------------------------------------------------
function Update-PwsExecutionPlan {
    $global:PwsExecutionPlan = @()
    foreach ($moduleName in $global:PwsConfig.Layout) {
        $functionName = "Get-Pws$moduleName"
        if (Test-Path "Function:\$functionName") {
            $global:PwsExecutionPlan += (Get-Item "Function:\$functionName")
        }
    }
}
# Compilamos por primera vez al arrancar
Update-PwsExecutionPlan

# ---------------------------------------------------------
# 5. EL PROMPT (Bucle Principal)
# ---------------------------------------------------------
function prompt {
    $lastCommandSuccess = $?
    $e = [char]27
    $promptString = ""

    if ($global:PwsConfig.Enabled) {
        # Ejecución directa desde la memoria RAM pre-compilada
        foreach ($func in $global:PwsExecutionPlan) {
            $promptString += & $func
        }
    } else {
        $promptString = "$e[90m[$([System.DateTime]::Now.ToString("HH:mm:ss"))]$e[0m $e[96m$($PWD.ProviderPath)$e[0m "
    }

    # Bloque Identificable Fijo
    $indicatorStr = if ($lastCommandSuccess) { 
        "$e[95m$($global:PwsConfig.Symbols.indicator)$e[0m" 
    } else { 
        "$e[91m$($global:PwsConfig.Symbols.error)$e[0m" 
    }
    
    return "$promptString`n$indicatorStr "
}