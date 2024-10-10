#----------------------------
# Create(enable) mailbox for user
# Created by HAB 31-01-2022
# Version 1.0
#----------------------------


#Exchange parameters
$exchangeAdmin = "^[ExchangeAdminID]"
$passwExAdmin = "^[ExchangePW]"
$secpassword = ConvertTo-SecureString "$passwExAdmin" -AsPlainText -Force
$Exdomain = "^[ExchangeDomain]"
$ExchangeDB = "^[ExchangeDatabase]"
$ExchangeServer= "^[ExchangeServer]"
$mailbox = "$[Mailbox]"
$user = "$[UserLogonName]"
$action = "$[Exchange_Enable]"
$exchangecred = New-Object System.Management.Automation.PSCredential (“$exchangeadmin”, $secpassword)

#Build PSsession with exchange server
$session = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri http://$exchangeserver/PowerShell/ -Authentication Kerberos -Credential $exchangecred
Import-PSSession $Session -DisableNameChecking


# determine user or mailbox
$userType = (Get-User -Identity $user).recipientType


if($action -eq "enable" -and $userType -eq "User")
    {
    # Enable mailbox
    Enable-Mailbox -Identity $user -database $ExchangeDB > $null
    $email = (Get-Mailbox $user).PrimarySMTPAddress
    $message = "Mailbox $email for $user is enabled."
    }
elseif($action -eq "enable" -and $userType -eq "UserMailbox")
    {
    # mailbox already enabled
    $email = (Get-Mailbox $user).PrimarySMTPAddress
    $message = "Mailbox $email for $user was already enabled."
    }
elseif($action -eq "disable" -and $userType -eq "UserMailbox")
    {
    # disable mailbox
    $email = (Get-Mailbox $user).PrimarySMTPAddress
    Disable-Mailbox -Identity $user -confirm:$false
    $message = "Mailbox $email for $user is disabled."
    }
elseif($action -eq "disable" -and $userType -eq "User")
    {
    # mailbox not found
    $message = "Mailbox for $user could not be found."
    }

Remove-PSSession $Session

$Global:message      = $message
$message