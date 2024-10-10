#--------------------------------------
# Add user to SAP System
# Created by HAB
# Date March 2022
# v.1.0
#-------------------------------------


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "text/xml; charset=utf-8")
$headers.Add("SOAPAction", "urn:sap-com:document:sap:soap:functions:mc-style:_-KRH_-USID_WS_CREA_USER_IN_SAP:_-krh_-usidWsCreaUserInSapRequest")
$headers.Add("Cookie", "sap-usercontext=sap-client=200")


#Create secure credential
$username = '^[WebService_Account]'
$password = '$[WebservicePassword]'
$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
$URL = <URL>

$body = '
<soapenv:Envelope xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:_-krh_-usidWsCreaUserInSap>
         <ISecureKey>$[SecureKey]</ISecureKey>
         <IsData>
            <PersonalNumber>$[EmployeeNumber]</PersonalNumber>
            <LastName>$[Lastname]</LastName>
            <FirstName>$[FirstName]</FirstName>
            <Title>$[Title]</Title>
            <Prefix>$[Prefix]</Prefix>
            <Gender>$[Gender]</Gender>
            <Salutation>$[Salutation]</Salutation>
            <NameText>$[FullName]</NameText>
            <KindOfDuty>$[Duty]</KindOfDuty>
            <KindOfContract>$[Contract]</KindOfContract>
            <EndOfContract>$[EndDate]</EndOfContract>
           <SapId>$[SapID]</SapId>
            <Email>$[Mailbox]</Email>
            <Active>$[Active]</Active>
         </IsData>
      </urn:_-krh_-usidWsCreaUserInSap>
   </soapenv:Body>
</soapenv:Envelope>
'

$response = Invoke-RestMethod '$URL' -Method 'PUT' -Headers $headers -Body $body -Credential $credential
$response = $response.Envelope.Body.'_-krh_-usidWsCreaUserInSapResponse'.EvAcknowledge
$Global:response = $Response