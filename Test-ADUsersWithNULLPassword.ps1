Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('domain')
$today = get-date
$collect = [System.Collections.Generic.List[System.Object]]::new()
$band32Users = Get-ADUser -Filter "useraccountcontrol -band 32" -Properties UserAccountControl,Enabled,AccountExpirationDate,LastLogonDate

foreach ($user in $band32Users) {
    if ($user.enabled -and -not ($null -ne $user.AccountExpirationDate -and $user.AccountExpirationDate -lt $today) -and $DS.ValidateCredentials($user.samAccountName, '')) {
        $badUser = [pscustomobject] @{
            samAccountName = $user.samAccountName
            LastLogonDate = $user.LastLogonDate
            userAccountControl = $user.UserAccountControl
            DN = $user.DistinguishedName
        }
        $collect.Add($badUser)
    }    
}

if ($collect.Count -gt 0) {
    $collect | Export-Csv "$PSScriptRoot\UsersWithNULLPasswords.csv" -NoTypeInformation
} else {
    [console]::WriteLine("Could not find users with NULL Passwords")
}
