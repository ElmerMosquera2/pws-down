function pws {
    param([switch]$activate, [switch]$disable)

    if ($activate) { 
        $global:PwsConfig.Enabled = $true
        Write-Host "✅ pws-down activado." -ForegroundColor Cyan 
    }
    if ($disable) { 
        $global:PwsConfig.Enabled = $false
        Write-Host "🌑 pws-down desactivado." -ForegroundColor Gray 
    }
    
    # Guardar cambios en el JSON para persistencia
    $global:PwsConfig | ConvertTo-Json | Out-File (Join-Path $global:PwsRoot "config/settings.json")
}
