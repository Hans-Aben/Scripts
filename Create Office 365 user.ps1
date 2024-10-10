#----------------------------------
# Created by HAB 09-05-2022
# Version 1.0
# Create Azure  Account
# v1.0
#---------------------------------

#install required module
Install-Module -Name AzureAD

# Parameter parsed by Automation
$AzureUsername = "<Azure admin>"
$AzurePassword = "<Password>"
$secpassword = ConvertTo-SecureString "$AzurePassword" -AsPlainText -Force
$AzureCredentials =  New-Object System.Management.Automation.PSCredential (“$AzureUsername”, $secpassword)

$GivenName     = "$[GivenName]"
$Surname       = "$[SurName]"
$Displayname   = "$[DisplayName]"
$EmailAddress  = "$[Email]"
$Mobile        = "$[Mobile]"
$Department    = "$[Department]"
$JobTitle      = "$[Job-Title]"
$UPN		   = "$[UPN]"
$Countrycode   = "NL"
$Licenseplan   = "$[Licensplan]"

# Connect to Microsoft Azure
Connect-AzureAD -Credential $AzureCredentials

# Create account

$PasswordProfile=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password="$password"
New-AzureADUser -DisplayName "$displayname" -GivenName "$GivenName" -SurName "$Surname" -UserPrincipalName "$UPN" -UsageLocation $Countrycode -MailNickName "$GivenName.$Surname" -PasswordProfile $PasswordProfile -AccountEnabled $true

Disconnect-AzureAD