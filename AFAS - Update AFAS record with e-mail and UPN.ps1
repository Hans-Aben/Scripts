#-----------------------------------------------
# AFAS - Update AFAS record with E-mail 
# Created by  HAB 19-09-2024
# v 2.0
#-----------------------------------------------


#AFAS Connectie
$token = "<token>"
$Url = "<URL>"

#Set parameters
$Employeenumber   = "12345" #usid
$Email            = "Test@test.com"                #emad



$encodedToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($token))

$authValue = "AfasToken $encodedToken"

$Headers = @{
    Authorization = $authValue
    }

$file = '
{
  "KnPerson": {
    "Element": {
      "Fields": {
        "MatchPer": "0",
        "BcCo": "'+$Employeenumber+'",
        "EmAd": "'+$email+'"
      }
    }
  }
}
'

Invoke-WebRequest -Uri $Url -ContentType appplication/json -UseBasicParsing -Method PUT -Headers $Headers -Body $file





#-----------------------------------------------
# AFAS - Update AFAS record with UPN 
# Created by  HAB 19-09-2024
# v 2.0
#-----------------------------------------------


#AFAS Connectie
$token = "<token>"
$Url = "<URL>"

#Set parameters
$Employeenumber   = "<CompanyID>.12345" #usid
$upn              = "Test@test.com"
$voornaam         = "Test"
$achternaam       = "Test"


$encodedToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($token))

$authValue = "AfasToken $encodedToken"

$Headers = @{
    Authorization = $authValue
    }

$file = '   {
  "KnUser": {
    "Element": {
      "@UsId": "'+$Employeenumber+'",
      "Fields": {
        "MtCd": 1,
      "Nm": "'+$voornaam+' '+$achternaam+'",
        "Upn": "'+$Upn+'"
      }
    }
  }
'
   
Invoke-WebRequest -Uri $Url -ContentType appplication/json -UseBasicParsing -Method PUT -Headers $Headers -Body $file