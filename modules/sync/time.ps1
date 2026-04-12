function Get-PwsTime {
    $now = [System.DateTime]::Now.ToString("HH:mm:ss")
    return [PSCustomObject]@{ Value = "[$now]"; Style = "time" }
}