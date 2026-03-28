function Get-PwsGit {
    $e = [char]27
    $branch = $null
    $current = $PWD.ProviderPath
    
    while ($current) {
        $headFile = [System.IO.Path]::Combine($current, ".git\HEAD")
        if ([System.IO.File]::Exists($headFile)) {
            try {
                $headContent = [System.IO.File]::ReadAllText($headFile).Trim()
                if ($headContent -match "ref: refs/heads/(.*)") { $branch = $matches[1] }
                else { $branch = $headContent.Substring(0, [math]::Min($headContent.Length, 7)) }
            } catch {}
            break
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current -or [string]::IsNullOrEmpty($parent)) { break }
        $current = $parent
    }

    if ($branch) { return "$e[93m($branch)$e[0m " }
    return ""
}
