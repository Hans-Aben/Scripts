#----------------------------------
# Created by HAB 04-01-2022
# Version 1.0
# Create Azure Guest Account
# Version 1.1 (07-01-2022)
# Added default Azure guest group
# 
#---------------------------------

# Parameter parsed by Automation
$AzureUsername = "^[AzureAD-Username]"
$AzurePassword = "^[AzureAD-Password]"
$secpassword = ConvertTo-SecureString "$AzurePassword" -AsPlainText -Force
$AzureCredentials =  New-Object System.Management.Automation.PSCredential (“$AzureUsername”, $secpassword)

$GivenName     = "$[GivenName]"
$Surname       = "$[SurName]"
$Displayname   = "$[DisplayName]"
$EmailAddress  = "$[Email]"
$CompanyName   = "$[Partner]"
$Mobile        = "$[Mobile]"
$Department    = "$[Department]"
$JobTitle      = "$[Job-Title]"

$InviteRedirectURL = "https://myapps.microsoft.com"

# Connect to Microsoft Azure
Connect-AzureAD -Credential $AzureCredentials

# Create the guest account and invite the user
$Object = New-AzureADMSInvitation -InvitedUserDisplayName $Displayname -InvitedUserEmailAddress $EmailAddress -InviteRedirectURL $InviteRedirectURL -SendInvitationMessage $true

# Update the newly created guest account
$User = Get-AzureADUser -ObjectId $object.InvitedUser.Id
$User.GivenName   = $GivenName
$User.Surname     = $Surname
$User.CompanyName = $CompanyName
if($Mobile){$User.Mobile = $Mobile}
if($Department){$User.Department  = $Department}
$User.JobTitle    = $JobTitle
$User.Displayname = $Displayname

Set-AzureADUser -ObjectId $object.InvitedUser.Id -GivenName $user.GivenName
Set-AzureADUser -ObjectId $object.InvitedUser.Id -Surname $user.Surname
Set-AzureADUser -ObjectId $object.InvitedUser.Id -CompanyName $user.CompanyName
if($Mobile){Set-AzureADUser -ObjectId $object.InvitedUser.Id -Mobile $user.Mobile}
if($Department){Set-AzureADUser -ObjectId $object.InvitedUser.Id -Department $user.Department}
Set-AzureADUser -ObjectId $object.InvitedUser.Id -JobTitle $user.JobTitle

$Global:ObjectID = $object.InvitedUser.Id