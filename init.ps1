$global:PwsRoot = Join-Path $HOME "pws-down"
$configFile = Join-Path $global:PwsRoot "config/settings.json"

# 1. Cargar Configuración
if (Test-Path $configFile) {
    $global:PwsConfig = Get-Content $configFile | ConvertFrom-Json
} else {
    # Valores por defecto si no existe el JSON
    $global:PwsConfig = [PSCustomObject]@{
        Layout = @("time", "duration", "path", "git")
        Enabled = $true
    }
}

# 2. Cargar Módulos (Dot-Sourcing)
# Esto carga las funciones en memoria una sola vez al abrir la terminal
Get-ChildItem (Join-Path $global:PwsRoot "modules/*.ps1") | ForEach-Object { . $_.FullName }

# 3. Función Prompt Dinámica
function prompt {
    $lastStatus = $?
    $promptString = ""

    if ($global:PwsConfig.Enabled) {
        # Recorre el layout definido en el JSON
        foreach ($moduleName in $global:PwsConfig.Layout) {
            # Busca y ejecuta la función correspondiente (ej: Get-PwsTime)
            $functionName = "Get-Pws$moduleName"
            if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                $promptString += & $functionName
            }
        }
    }

    # Bloque Identificable (Final)
    $indicator = if ($lastStatus) { "`e[95m>>`e[0m" } else { "`e[91m✘ >>`e[0m" }
    return "$promptString`n$indicator "
}
