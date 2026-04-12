function Get-PwsBattery {
    try {
        $bateria = Get-CimInstance -ClassName Win32_Battery -Property BatteryStatus, EstimatedChargeRemaining -ErrorAction Stop
        if ($null -eq $bateria -or $null -eq $bateria.EstimatedChargeRemaining) { return $null }

        $porcentaje = [math]::Round($bateria.EstimatedChargeRemaining)
        $estado = $bateria.BatteryStatus

        $style = "battery_full"
        if ($porcentaje -le 15) { $style = "battery_low" }
        elseif ($porcentaje -le 30) { $style = "battery_medium" }

        $icono = switch ($estado) {
            2 { "⚡🔋" }      # Cargando
            3 { "✅🔋" }      # Cargado
            default {
                if ($porcentaje -le 10) { "🪫" }
                elseif ($porcentaje -le 15) { "⚠️🔋" }
                else { "🔋" }
            }
        }

        # Escribe directo en la tabla compartida
        $global:PwsSnapshot.Battery = [PSCustomObject]@{ Value = "$icono $($porcentaje)%"; Style = $style }
    } catch {
        $global:PwsSnapshot.Battery = $null
    }
}