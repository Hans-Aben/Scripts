#---------------------------
# Created by HAB 06-01-2021
# This script will change
# the Azure guest account
#---------------------------



# Parameter parsed by Automation
$AzureUsername = "^[AzureAD-Username]"
$AzurePassword = "^[AzureAD-Password]"
$secpassword = ConvertTo-SecureString "$AzurePassword" -AsPlainText -Force
$AzureCredentials =  New-Object System.Management.Automation.PSCredential (“$AzureUsername”, $secpassword)


# Connect to Microsoft Teams
Connect-AzureAD -Credential $AzureCredentials

#Get Azure Object ID from user

$M365ID = (get-azureaduser -objectid '$[O365Mail]#EXT#@qlag.onmicrosoft.com').objectid
$GivenName     = "$[GivenName]"
$Surname       = "$[Surname]"
$Displayname   = "$[Displayname]"
$EmailAddress  = "$[E-mail]"
$Mobile        = "$[Mobile]"
$Department    = "$[Deparment]"
$JobTitle      = "$[JobTitle]"
$CompanyName   = "$[CompanyName]"


# Update the guest account
$User = Get-AzureADUser -ObjectId $M365ID
$User.DisplayName  = $DisplayName
$User.GivenName    = $GivenName
$User.Surname      = $Surname
$User.Mobile       = $Mobile
$User.Department   = $Department
$User.JobTitle     = $JobTitle
$User.CompanyName  = $CompanyName

If($DisplayName) {Set-AzureADUser -ObjectId $M365ID -DisplayName $user.DisplayName}
If($GivenName) {Set-AzureADUser -ObjectId $M365ID -GivenName $user.DisplayName}
If($Surname) {Set-AzureADUser -ObjectId $M365ID -Surname $user.Surname}
If($Mobile) {Set-AzureADUser -ObjectId $M365ID -Mobile $user.Mobile}
If($Department) {Set-AzureADUser -ObjectId $M365ID -Department $user.Department}
If($JobTitle) {Set-AzureADUser -ObjectId $M365ID -JobTitle $user.JobTitle}
If($CompanyName) {Set-AzureADUser -ObjectId $M365ID -CompanyName $user.CompanyName}