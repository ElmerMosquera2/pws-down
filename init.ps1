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

# 2. Cargar Módulos y Controlador
Get-ChildItem (Join-Path $global:PwsRoot "modules\*.ps1") | ForEach-Object { . $_.FullName }
. (Join-Path $global:PwsRoot "controller.ps1")

# ---------------------------------------------------------
# 🔥 NUEVO: PRE-COMPILACIÓN DEL PLAN DE EJECUCIÓN
# ---------------------------------------------------------
# Buscamos las funciones UNA SOLA VEZ en el arranque.
$global:PwsExecutionPlan = @()

foreach ($moduleName in $global:PwsConfig.Layout) {
    $functionName = "Get-Pws$moduleName"
    # Si la función existe, guardamos su referencia directa en memoria
    if (Test-Path "Function:\$functionName") {
        $global:PwsExecutionPlan += (Get-Item "Function:\$functionName")
    }
}
# ---------------------------------------------------------

# 3. El Prompt Principal (Latencia Cero)
function prompt {
    $lastCommandSuccess = $?
    $e = [char]27
    $promptString = ""

    if ($global:PwsConfig.Enabled) {
        # Ejecutamos las referencias directas de la RAM, sin buscar comandos.
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
