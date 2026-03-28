function Get-PwsTime {
    $e = [char]27
    $now = [System.DateTime]::Now.ToString("HH:mm:ss")
    return "$e[90m[$now]$e[0m "
}
