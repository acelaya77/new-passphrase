
Function New-Passphrase {
<#
.SYNOPSIS
    This generates a passphrase for use with provisioning new accounts or
    resetting passwords in AD.


.NOTES
    Name: New-Passphrase
    Author: Anthony J. Celaya
    Version: 2.0
    DateCreated: 2021-07-21
    Default Word Count: 3
    Default max word length: 6


.EXAMPLE
    $myPassphrase = New-Passphrase
    $myPassphrase

                AccountPassword PlainPassword            Url
                --------------- -------------            ---
    System.Security.SecureString Slain_enable_144_galley. https://pwpush.com/p/u6kkszzqsx4    

#>
    [cmdletbinding()]
    Param(
        [Parameter()]
        [ValidateRange(3, 32)]
        [int]$WordCount = 3,
        
        [Parameter()]
        [ValidateRange(3, 32)][int]$MaxCharacterLength = 6,
        
        [Parameter()]
        [Switch]$NewList
    )#end Param()

    $beginVars = Get-Variable -Scope:Script | Select-Object -ExpandProperty Name

    #Our path
    if ([string]::IsNullOrEmpty($path)) {
        if ( [string]::IsNullOrEmpty( (Split-Path (Get-Module New-Passphrase).path ) ) ) {
            $path = (Get-Location)
        }
        else {
            $path = (Split-Path (Get-Module New-Passphrase).path )
        }
    }
    write-verbose $path
    
    #Build words list
    $wordsPath = (Join-Path $path 'words.txt')
    'Using path: {0}' -f $wordsPath | Write-Verbose
    if ( ($PSBoundParameters.ContainsKey('NewList')) ) {
        if ( (Test-Path($wordsPath)) -and !($PSBoundParameters.ContainsKey('NewList')) ) {
            Write-Verbose "Using existing word list.  To override use -NewList parameter."
        } else {
            $(Invoke-WebRequest 'https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt' -OutFile:.\words_raw.txt -PassThru).Content.Split("`n") |
            Select-String '\d{1,}\s+(\w+)' | 
            ForEach-Object { $_.Matches.Groups[1].Value } | 
            Set-Content (Join-Path '.' words.txt)
        }
    }
    $words = $(Get-Content $wordsPath)
    
    $script:rndWords = $Null
    while ( [string]::IsNullOrEmpty($script:rndWords) ) {
        $stopWatch = [system.diagnostics.stopwatch]::startNew()
        $script:rndWords = $($words.where({ $PSItem.length -le $MaxCharacterLength })) | Get-Random -Count $WordCount
    }
    $stopWatch.Stop()
    Write-Verbose $('Word count: {0}, time: {1}' -f $($words.count), $stopWatch.Elapsed.ToString('mm\m\:ss\.ffff\s'))
    
    $punctuation = $(@('.', '?', '!') | Get-Random)
    $space = (@(' ', '_','-') | Get-Random)
    $numerals = ((0..665), (667..999) | Get-Random )
    $word1 = $((Get-Culture).TextInfo.ToTitleCase($script:rndWords[0]))
    $wordMiddle = $script:rndWords[1..($WordCount - 2)]
    $wordLast = $($script:rndWords[$WordCount - 1])
    $collection = @()
    $collection += $word1
    $collection += @($wordMiddle,$wordLast,$numerals) | Get-Random -Count:3
    $strPassword = '{0}{1}' -f [string]::Join($space, $collection), $punctuation
    $returnObject = $(ConvertTo-SecureString -Force -AsPlainText $strPassword) | ForEach-Object {
        New-Object Object |
        Add-Member -NotePropertyName:'AccountPassword' -NotePropertyValue:$_ -PassThru |
        Add-Member -NotePropertyName:'PlainPassword' -NotePropertyValue:$strPassword -PassThru
    }
    
    $passwd = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ReturnObject.AccountPassword))
    $payload = @'
    {0}
    "password": 
    {0}
    "payload": "{2}",
    "expire_after_days": "7",
    "expire_after_views": "4",
    "note": "dateTime: {3}",
    "retrieval_step": "false",
    "deletable_by_viewer": "true"
    {1}
    {1}
'@ -f '{', '}', $passwd, (Get-Date -f 's')


    $r = Invoke-RestMethod -Method Post -Uri 'https://pwpush.com/p.json' -ContentType:'application/json' -Body:$payload
    $url = 'https://pwpush.com/p/{0}' -f $r.url_token
    $returnObject | Add-Member -NotePropertyName:'Url' -NotePropertyValue:$url

    $endVars = Get-Variable -Scope:Script | Select-Object -ExpandProperty Name | Where-Object{ $_ -notin $beginVars }
    $endVars | Write-Verbose
    Return $returnObject
    
    #Let's remove any variables
    @('rndWords', 'strPassword', 'password', 'myReturnObject', 'swearWords') | Get-Variable -Scope Script -ErrorAction SilentlyContinue -ErrorVariable getVarErrors | Remove-Variable -ErrorAction SilentlyContinue -ErrorVariable removeVarErrors
    $VerbosePreference = $oldVerbose
    
}#end function New-Passphrase
