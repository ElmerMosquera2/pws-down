function Get-PwsPath {
    $e = [char]27
    $path = $PWD.ProviderPath
    $shortPath = $path -replace "^$([regex]::Escape($HOME))", "~"
    
    # Actualiza el título de la ventana de paso
    $host.UI.RawUI.WindowTitle = "PS: $shortPath"
    
    return "$e[92m$env:USERNAME$e[0m+$e[96m$shortPath$e[0m "
}
