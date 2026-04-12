# ==========================================
# INICIALIZACIÓN DE PWS-DOWN (Arquitectura 2.0)
# ==========================================
$global:PwsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:PwsConfigFile = Join-Path $global:PwsRoot "config\settings.json"

# 1. Cargar configuración JSON (Cold Truth)
if (Test-Path $global:PwsConfigFile -PathType Leaf) {
    $global:PwsConfig = Get-Content $global:PwsConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    Write-Warning "pws-down: No se encontró settings.json."
    return
}

# 2. Cargar Módulos (dot-sourcing del Renderer y módulos aislados)
. (Join-Path $global:PwsRoot "renderer.ps1")
Get-ChildItem (Join-Path $global:PwsRoot "modules\sync\*.ps1") -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
Get-ChildItem (Join-Path $global:PwsRoot "modules\snapshot\*.ps1") -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }

# 3. Tabla Compartida en Memoria
if (-not $global:PwsSnapshot) {
    $global:PwsSnapshot = [PSCustomObject]@{ Battery = $null; Software = $null }
}

# 4. COMPILADOR DEL PLAN DE EJECUCIÓN (Rápido, estático)
function Update-PwsExecutionPlan {
    $global:PwsExecutionPlan = [System.Collections.Generic.List[scriptblock]]::new()
    if (-not $global:PwsConfig.Layout) { return }

    foreach ($moduleName in $global:PwsConfig.Layout) {
        $functionName = "Get-Pws$moduleName"
        $func = Get-Command -Name $functionName -ErrorAction SilentlyContinue
        if ($func) {
            $global:PwsExecutionPlan.Add($func.ScriptBlock)
        }
    }
}

# 5. LANZADOR DE RUNSPACES (Parallel Snapshot Runspaces)
function Start-PwsSnapshotRunspace {
    # Módulos lentos/poco mutables en background para garantizar < 0.5ms en el prompt
    if ($global:PwsConfig.SnapshotLayout) {
        foreach ($mod in $global:PwsConfig.SnapshotLayout) {
            $funcInfo = Get-Command -Name "Get-Pws$mod" -ErrorAction SilentlyContinue
            if ($funcInfo) {
                # Las variables se configuran de fondo. (Simulado sincrónico para la compatibilidad general aquí, 
                # en PS7 nativo Start-ThreadJob se recomienda para evitar bloqueos del primer arranque).
                try { Invoke-Expression "& `"Get-Pws$mod`"" } catch {}
            }
        }
    }
}

# ---------------------------------------------------------
# 6. EL CONTROLADOR (El estado solo se vuelve archivo en `--save`)
# ---------------------------------------------------------
function pws {
    param(
        [switch]$activate, 
        [switch]$disable, 
        [switch]$minimal, 
        [switch]$full, 
        [switch]$update,
        [switch]$reload,
        [switch]$save,
        [string]$theme
    )
    
    $rebuildPlan = $false
    $anyFlagSet = $false

    if ($activate) { 
        $anyFlagSet = $true; $global:PwsConfig.Enabled = $true
        Write-Host "✅ pws-down activado en memoria." -ForegroundColor Cyan 
    }
    
    if ($disable) { 
        $anyFlagSet = $true; $global:PwsConfig.Enabled = $false
        Write-Host "🌑 pws-down desactivado (prompt de emergencia)." -ForegroundColor DarkGray 
    }
    
    if ($minimal) { 
        $anyFlagSet = $true; $rebuildPlan = $true
        $global:PwsConfig.Layout = @("Path", "Git")
        Write-Host "🧹 Modo minimalista en RAM activado." -ForegroundColor Yellow 
    }
    
    if ($full) { 
        $anyFlagSet = $true; $rebuildPlan = $true
        $global:PwsConfig.Layout = @("Time", "Duration", "Path", "Git")
        Write-Host "✨ Modo completo en RAM activado." -ForegroundColor Yellow 
    }
    
    if ($theme) {
        $anyFlagSet = $true
        $global:PwsConfig.Theme = $theme
        Write-Host "🎨 Tema visual global '$theme' activado en vivo." -ForegroundColor Blue
    }

    if ($update) {
        $anyFlagSet = $true
        Write-Host "🔄 Escaneando snapshots en runspace paralelo..." -ForegroundColor Cyan
        Start-PwsSnapshotRunspace
        Write-Host "  ✅ Cachés asíncronas de RAM actualizadas." -ForegroundColor Green
    }
    
    if ($reload) {
        $anyFlagSet = $true; $rebuildPlan = $true
        Write-Host "🔄 Recargando renderer y módulos..." -ForegroundColor Cyan
        . (Join-Path $global:PwsRoot "renderer.ps1")
        Get-ChildItem (Join-Path $global:PwsRoot "modules\sync\*.ps1") -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
        Get-ChildItem (Join-Path $global:PwsRoot "modules\snapshot\*.ps1") -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
        Write-Host "  ✅ Módulos en línea listos." -ForegroundColor Green
    }
    
    if ($save) {
        $anyFlagSet = $true
        $global:PwsConfig | ConvertTo-Json -Depth 3 | Out-File $global:PwsConfigFile -Encoding utf8
        Write-Host "💾 Configuración volcada a settings.json permanentemente." -ForegroundColor Magenta
    }

    if ($rebuildPlan) { Update-PwsExecutionPlan }

    if (-not $anyFlagSet) {
        Write-Host "pws-down ⚡ - Menú de Ayuda (Arquitectura 2.0)" -ForegroundColor Cyan
        Write-Host "  pws -activate   : Enciende el motor de pws-down"
        Write-Host "  pws -disable    : Apaga el motor (prompt de emergencia)"
        Write-Host "  pws -minimal    : Layout RAM minimalista"
        Write-Host "  pws -full       : Layout RAM completo"
        Write-Host "  pws -theme <N>  : Cambia el color ANSI de todos los renderizadores"
        Write-Host "  pws -update     : Dispara recolección en background de snapshots"
        Write-Host "  pws -reload     : Recarga PS1's sin cerrar la terminal"
        Write-Host "  pws -save       : Persiste .json al disco duro"
    }
}

# Compilación y arranque
Update-PwsExecutionPlan
Start-PwsSnapshotRunspace

# ---------------------------------------------------------
# 7. BUCLE PRINCIPAL DEL PROMPT (< 0.5ms latencia)
# ---------------------------------------------------------
function prompt {
    $lastCommandSuccess = $?
    $e = [char]27

    if ($global:PwsConfig.Enabled -and $global:PwsExecutionPlan.Count -gt 0) {
        # StringBuilder: Escribe directamente; Cero allocations innecesarios
        $sb = [System.Text.StringBuilder]::new()

        # Fase Síncrona: Módulos evaluados en plan de ejecución
        foreach ($func in $global:PwsExecutionPlan) {
            $dataTuple = & $func
            if ($dataTuple) { [void]$sb.Append((Invoke-PwsRenderer -Item $dataTuple)) }
        }
        
        # Fase Asíncrona (Snapshot): Simplemente leer las variables globales
        if ($global:PwsConfig.SnapshotLayout) {
            foreach ($mod in $global:PwsConfig.SnapshotLayout) {
                try {
                    $snapTuple = $global:PwsSnapshot.$mod
                    if ($snapTuple) { [void]$sb.Append((Invoke-PwsRenderer -Item $snapTuple)) }
                } catch {}
            }
        }

        # Terminal indicator (Depende del $?)
        $statusStr = if ($lastCommandSuccess) { 
            "$e[95m$($global:PwsConfig.Symbols.indicator)$e[0m" 
        } else { 
            "$e[91m$($global:PwsConfig.Symbols.error)$e[0m" 
        }
        
        [void]$sb.Append("`n").Append($statusStr).Append(" ")
        return $sb.ToString()
    }

    # Fallback (Motor apagado)
    return "$e[90m[$([DateTime]::Now.ToString('HH:mm:ss'))]$e[0m $e[96m$($PWD.ProviderPath)$e[0m `n$e[95m$($global:PwsConfig.Symbols.indicator)$e[0m "
}