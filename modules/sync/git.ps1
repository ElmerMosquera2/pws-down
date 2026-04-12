function Get-PwsGit {
    $e = [char]27
    $branch = $null
    
    # Usa FileSystemWatcher en el backend (esto se implementaría de forma avanzada), 
    # pero aquí vamos a usar la lectura ligera.
    # Para cumplir con < 0.1ms usaremos una caché simple ligada al directorio actual:
    $current = $PWD.ProviderPath

    if ($null -ne $script:GitCache -and $script:GitCachePath -eq $current) {
        # Si prefiere FileSystemWatcher real, se puede incluir un init o similar, pero un check del path 
        # asido a lastwrite time sirve de watcher.
        $headPath = $script:GitCacheHead
        if (([System.IO.File]::GetLastWriteTime($headPath) -eq $script:GitCacheLastWrite) -or -not [System.IO.File]::Exists($headPath)) {
            return $script:GitCacheResult
        }
    }

    $headFile = $null
    $searchDir = $current
    while ($searchDir) {
        $tempFile = [System.IO.Path]::Combine($searchDir, ".git\HEAD")
        if ([System.IO.File]::Exists($tempFile)) {
            $headFile = $tempFile
            try {
                $headContent = [System.IO.File]::ReadAllText($headFile).Trim()  
                if ($headContent -match "ref: refs/heads/(.*)") { $branch = $matches[1] }
                else { $branch = $headContent.Substring(0, [math]::Min($headContent.Length, 7)) }
            } catch {}
            break
        }
        $parent = [System.IO.Path]::GetDirectoryName($searchDir)
        if ($parent -eq $searchDir -or [string]::IsNullOrEmpty($parent)) { break }
        $searchDir = $parent
    }

    $result = $null
    if ($branch) { 
        $result = [PSCustomObject]@{ Value = "($branch)"; Style = "git" }
    }

    # Actualizar cache
    $script:GitCachePath = $current
    $script:GitCacheResult = $result
    $script:GitCacheHead = $headFile
    if ($headFile -and [System.IO.File]::Exists($headFile)) {
        $script:GitCacheLastWrite = [System.IO.File]::GetLastWriteTime($headFile)
    }

    return $result
}