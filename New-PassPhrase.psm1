
$scripts = Get-ChildItem (join-Path $PSScriptRoot 'Scripts\*') -Include:@('*.ps1')
foreach ( $script in $scripts ){
    . $script.FullName
}

Export-ModuleMember -Function:'New-PassPhrase'
