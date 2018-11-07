﻿
Function Resort-NewAccountLog{
$inputCSV = Import-Csv -Path "I:\Continuity\Celaya\AD\NewAccountsLog.csv" 

#$inputCSV | sort whenCreated -Descending | ft -AutoSize

$colImported = @()

foreach($item in $inputCSV){
    $colImported += [PSCustomObject] @{
        whenCreated = [DateTime]"$($item.whenCreated)"
    }
}

#Rename-Item -Path "I:\Continuity\Celaya\AD\NewAccountsLog.csv" -NewName "NewAccountsLog.csv.$(Get-Date -f 'yyyyMMdd-HHmmss')"
"Last Run:`r`n$(Get-Date -f 'yyyyMMdd-HHmmss')`r`n" | Out-File "I:\Continuity\Celaya\AD\NewAccountsLog-Backup.csv"
gc -Path "I:\Continuity\Celaya\AD\NewAccountsLog.csv" | Out-File "I:\Continuity\Celaya\AD\NewAccountsLog-Backup.csv" -Append

$colImported | sort -Descending whenCreated | export-csv -NoTypeInformation -Delimiter "," -Path "I:\Continuity\Celaya\AD\NewAccountsLog.csv" 
}#end Function Resort-NewAccountLog{}