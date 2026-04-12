function Get-PwsSoftware {
    try {
        $pyPath = "HKCU:\Software\Python\PythonCore"
        if (Test-Path $pyPath) {
            $ver = (Get-ChildItem $pyPath | Select-Object -First 1 -ExpandProperty PSChildName)
            if ($ver) {
                $global:PwsSnapshot.Software = [PSCustomObject]@{ Value = "🐍 v$ver"; Style = "software" }
                return
            }
        }
    } catch {}
    
    $global:PwsSnapshot.Software = $null
}