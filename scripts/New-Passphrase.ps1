
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
    [cmdletbinding(SupportsShouldProcess)]
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
    $path = (Split-Path $PSCommandPath -Parent)
    'Command path: {0}' -f $PSCommandPath | Write-Verbose
    $path | Write-Verbose
<# 
    if ([string]::IsNullOrEmpty($path)) {
        if ( [string]::IsNullOrEmpty( (Split-Path (Get-Module New-Passphrase).path ) ) ) {
            $path = (Get-Location)
        }
        else {
            $path = (Split-Path (Get-Module New-Passphrase).path )
        }
    }
 #>
    
    #Build words list
    $wordsPath = (Join-Path $path 'words.txt')
    $wordsRawPath = (Join-Path $path 'words_raw.txt')
    'Using path: {0}' -f $wordsPath | Write-Verbose
    if ( ($PSBoundParameters.ContainsKey('NewList')) -or !(Test-Path($wordsPath))) {
        if ( (Test-Path($wordsPath)) -and !($PSBoundParameters.ContainsKey('NewList')) ) {
            Write-Verbose "Using existing word list.  To override use -NewList parameter."
        } else {
            $oldProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue'
            $webRequest = Invoke-WebRequest 'https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt' -OutFile:$wordsRawPath #-PassThru
            $ProgressPreference = $oldProgressPreference
            ('Downloading and saving list: {0}' -f $wordsRawPath) | Write-Verbose
            if ( $webRequest.StatusCode -eq 200 ){ 'Downlaod complete' | Write-Verbose }
            'Parsing file: {0}' -f $wordsPath | Write-Verbose
            (Get-Content $wordsRawPath).Split("`n") |
                Select-String '\d{1,}\s+(\w+)' | 
                ForEach-Object { $_.Matches.Groups[1].Value } | 
                Set-Content $wordsPath
        }
    }
    $counter = 0
    do{
        $isValid = Test-Path $wordsPath
        $counter++
        if ($counter -gt 1){ Start-Sleep -Milliseconds:600 }
    }Until($isValid -or $counter -gt 20)
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
    $returnObject
    
    #Let's remove any variables
    @('rndWords', 'strPassword', 'password', 'myReturnObject', 'swearWords') | Get-Variable -ErrorAction Ignore -ErrorVariable getVarErrors -Scope Script | Remove-Variable -ErrorAction Ignore -ErrorVariable removeVarErrors
    $VerbosePreference = $oldVerbose
    
}#end function New-Passphrase
