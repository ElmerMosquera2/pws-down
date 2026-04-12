function Get-PwsDuration {
    $e = [char]27
    $history = Get-History -Count 1 -ErrorAction Ignore
    if ($history) {
        $duration = [math]::Round(($history.EndExecutionTime - $history.StartExecutionTime).TotalMilliseconds)
        if ($duration -gt 50) {
            if ($duration -gt 1000) {
                return [PSCustomObject]@{ Value = "⏱️ $([math]::Round($duration/1000, 2))s"; Style = "duration_slow" }
            } else {
                return [PSCustomObject]@{ Value = "⚡ ${duration}ms"; Style = "duration_fast" }
            }
        }
    }
    return $null
}