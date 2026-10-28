Import-Module ActiveDirectory

# Import employee information
$Users = Import-Csv "C:\Scripts\NewUsers.csv"

# Prompt for an initial password
$Password = Read-Host "Enter initial password" -AsSecureString

# Active Directory domain
$Domain = "corp.example.test"
$BaseOU = "OU=Company Users,DC=corp,DC=example,DC=test"

foreach ($User in $Users) {

    $FirstName = $User.FirstName.Trim()
    $LastName = $User.LastName.Trim()
    $Department = $User.Department.Trim()

    # Generate username: first initial + last name
    $Username = ($FirstName.Substring(0,1) + $LastName).ToLower()

    # Determine OU and security group
    $OU = "OU=$Department,$BaseOU"
    $Group = "GG_$Department"

    # Check whether the account already exists
    if (Get-ADUser -Filter "SamAccountName -eq '$Username'") {
        Write-Host "Skipping $Username - account already exists"
        continue
    }

    # Create the user account
    New-ADUser `
        -Name "$FirstName $LastName" `
        -GivenName $FirstName `
        -Surname $LastName `
        -SamAccountName $Username `
        -UserPrincipalName "$Username@$Domain" `
        -Path $OU `
        -AccountPassword $Password `
        -ChangePasswordAtLogon $true `
        -Enabled $true

    # Add user to departmental security group
    Add-ADGroupMember -Identity $Group -Members $Username

    Write-Host "Created $Username in $Department"
}