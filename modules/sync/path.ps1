function Get-PwsPath {
    $e = [char]27
    $path = $PWD.ProviderPath
    $shortPath = $path -replace "^$([regex]::Escape($HOME))", "~"

    # Actualiza el título de la ventana de paso
    $host.UI.RawUI.WindowTitle = "PS: $shortPath"

    # Formato mixto: User en color User y path en color path.
    # Dado que es complejo separarlos, vamos a usar Style="raw" o lo componemos.
    # Para la nueva filosofía, pasaremos el string ya coloreado con un Style="raw", o
    # simplemente "Path" e imprimimos solo el path. Voy a retornar raw para mantener la esencia actual.
    
    # Sin embargo, la filosofía busca separar datos/presentacion. 
    # El color deberia manejarlo el renderer.
    # Mandamos raw para no perder las características de color diferentes:
    $theme = $global:PwsConfig.Theme
    if ([string]::IsNullOrEmpty($theme)) { $theme = "default" }
    $userColor = "92m"
    $pathColor = "96m"

    return [PSCustomObject]@{ Value = "$e[${userColor}$env:USERNAME$e[0m+$e[${pathColor}$shortPath$e[0m"; Style = "raw" }
}