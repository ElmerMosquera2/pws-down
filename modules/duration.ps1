function Get-PwsDuration {
    $e = [char]27
    $history = Get-History -Count 1 -ErrorAction Ignore
    if ($history) {
        $duration = [math]::Round(($history.EndExecutionTime - $history.StartExecutionTime).TotalMilliseconds)
        if ($duration -gt 50) {
            if ($duration -gt 1000) { 
                return "$e[38;5;208m⏱️ $([math]::Round($duration/1000, 2))s$e[0m " 
            } else { 
                return "$e[33m⚡ ${duration}ms$e[0m " 
            }
        }
    }
    return ""
}
