function Get-PwsTime {
    $now = [System.DateTime]::Now.ToString("HH:mm:ss")
    return "`e[90m[$now]`e[0m "
}
