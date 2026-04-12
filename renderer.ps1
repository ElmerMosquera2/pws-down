# ==========================================
# RENDERER CENTRAL (pws-down)
# ==========================================
# Recibe objetos { Value, Style } y aplica el color ANSI correspondiente.

function Invoke-PwsRenderer {
    param([PSCustomObject]$Item)
    
    if ($null -eq $Item -or [string]::IsNullOrEmpty($Item.Value)) { return "" }
    
    $e = [char]27
    $themeName = $global:PwsConfig.Theme
    if ([string]::IsNullOrEmpty($themeName)) { $themeName = "default" }

    # Definición de temas
    $themes = @{
        "default" = @{
            "time"              = "90m"        # Gris oscuro
            "path"              = "96m"        # Cyan
            "git"               = "93m"        # Amarillo claro
            "duration_fast"     = "33m"        # Amarillo
            "duration_slow"     = "38;5;208m"  # Naranja
            "battery_full"      = "92m"        # Verde claro
            "battery_medium"    = "93m"        # Amarillo claro
            "battery_low"       = "91m"        # Rojo claro
            "software"          = "94m"        # Azul claro
            "user"              = "92m"        # Verde
            "reset"             = "0m"
        }
    }

    $palette = $themes[$themeName]
    if ($null -eq $palette) { $palette = $themes["default"] }

    # Como Path y Battery pueden tener múltiples colores en su formato devuelto,
    # el Renderer permite que Style sea una instrucción de color simple,
    # o que el modulo devuelva algo pre-formateado si Style es "raw".
    
    if ($Item.Style -eq "raw") {
        return "$($Item.Value) "
    }

    $color = $palette[$Item.Style]
    if ($null -eq $color) { $color = "0m" }

    return "$e[$color$($Item.Value)$e[0m "
}