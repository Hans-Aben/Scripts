#---------------------------
# Created by HAB 03-01-2021
# This script will create
# an ticket in JIRA
#---------------------------


# Get the current date

$date= get-date -format yyyy/MM/dd
#ict
$inputString=  "Benötigen sie einen Tisch? = Nein; Benötigen sie einen Stuhl? = Nein; Manager = Andreas Sterchi; Date = 2023/04/05; Subscriber = Edon Ademi; StartDate = 01.08.2023; Bemerkung = keine; Büro = Arbeitsplatz von ehemaligem Lernenden"
$inputString= $inputString.Replace('"','')
$inputString= $inputString.Replace("'","")

# Translate English to German Dictionary
$lookupTable = @{
    'Startdate' = 'Eintrittsdatum'   
    'Subscriber' = 'Mitarbeiter'
    'Remark' = 'Bemerkungen'
    'manager' = 'Vorgesetzter'
    'Orderdate' = 'Bestelldatum'
    'Office' = 'Standort'
    'no' = 'Nein'
    'yes' = 'Ja'   
    'Desk' = 'Bürotisch'
    'Chair' = 'Bürostuhl'
    'Language' = 'Sprache'
    'Monitors' = 'Monitore'
}



# German
$lookupTable.GetEnumerator() | ForEach-Object {
    if ($inputString -match $_.Key){   
        $inputString = $inputString -replace $_.Key, $_.Value
    }
}
$ht = @{} # declare empty hashtable
$inputString -split '; ' | % { $s = $_ -split ' = '; $ht += @{$s[0] =  $s[1]}} 

# Create general ticket information 
$string = "Guten Tag, bitte stellt das unten aufgelistete Material zu Verfügung:" +"\r\n  \r\n"
$string += "*Eintrittsdatum: " +  $ht."Eintrittsdatum" +"*\r\n "
$string += "Bestelldatum: " +   $ht."Bestelldatum"+"\r\n "
$string += "Mitarbeiter: " +   $ht."Mitarbeiter" +"\r\n "
$string += "Vorgesetzter: " +  $ht."Vorgesetzter" +"\r\n "
$string += "Standort: " + $ht."Standort" +"\r\n "
$string += "Bemerkungen: " + $ht."Bemerkungen" +"\r\n "

$ht.Remove("Bestelldatum")
$ht.Remove("Mitarbeiter")
$ht.Remove("Vorgesetzter")
$ht.Remove("Eintrittsdatum")
$ht.Remove("Standort")
$ht.Remove("Bemerkungen")


# Specific ticket information 
$string += "\r\n "
$string += "*Bestellung:* \r\n "

foreach($key in $ht.Keys){
    $string += $key+ ": " +  $ht.$key +"\r\n"    
}


# Jira String
$string 

$summary = 'This is an automatic generated Jira request for Test Ivant'
$description = "$string"
$createticket =$true
$managersam  = "<manager>"

$base64AuthInfo = "<APIKey>"
$restapiuri = <URL>"
$body = ('
    {
        "fields": {
           "project":
           {
              "key": "ICS"
           },
           "summary": "'+ $summary +'",
           "description": "'+ $description +'",
           "issuetype": {
              "name": "Supportcase"
           }
       }
    }
')

if($createticket){
                  
                  # Take Result of the new created Ticket
                  $TicketResult =  Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}  -uri $restapiuri  -Method POST -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
                  
                  # JIRA Issue Key of new Ticket
                  $NewKey = $TicketResult.key
                  
                  # Assignee API Uri
                  $AssignApiUri = "$restapiuri/$newkey/assignee"

                  # Assignee Body, Replace Name of Manager
                  $ManagerBody = ('{
                        "name": "'+ $managersam +'"
                    }
                  ')

                  # Assignee Request
                  Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}  -uri $AssignApiUri  -Method Put -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($ManagerBody))
                  
                }else{
                    #this is only for testing when createticket is false
                    '' | Select-Object @{n='id';e={'9999999'}},@{n='key';e={'ICS-999'}},@{n='self';e={'$restapiuri/999999'}}
                }

