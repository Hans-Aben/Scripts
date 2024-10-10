#HR2Day parameters
$username = 'apiivanti@rensa.hr2d.com'
$password = 'tfxAPiUserSBSB3HR2detmenS#@tp67DR64feRqLf2lTgoq5rtIYAdI1'
$clientid = '3MVG91BJr_0ZDQ4s.cCHvMb1f7_go22ku9rSHiBc842LFIhQ36_qB22gc6GFQ4URjtlOfULnPPOwg4x3pWMLM'
$clientsecret = "6F6DEE314C5B6062AA5B47DEA2D86BF549B4962E90A443AED50C832B6F75DF5A"
$BaseUrl = "https://hr2day-9521.cloudforce.com/services/apexrest/hr2d/"

# sql variables
$sqlServer   = "<DBServer>" 
$sqlDBName   = "DBName> 
$sqlAdmin    = '<DBAdmin>'
$sqlDBTable    = "<SQLTable>"
$sqlPassword = '<SQLPassword>'
$sqlArray    = $null
$deleted     = $null
$deletes     = $null

$sqlArray = @()
$usrArray = @()
$deletes  = @()
$added    = 0
$updated  = 0
$deleted  = 0


#Setup connection to HR2Day

        Write-Verbose "Invoking command '$($MyInvocation.MyCommand)'"
        Write-Verbose 'Retrieving HR2Day AccessToken'
        $form = @{
            grant_type    = 'password'
            username      = $UserName
            client_id     = $ClientID
            client_secret = $clientSecret
            password      = $Password
        }
        $accessToken = Invoke-RestMethod -Uri 'https://login.salesforce.com/services/oauth2/token' -Method Post -body $form
        $Bearer = $accessToken.access_token
        $authorizationheader =@{ Authorization="Authorization: Bearer $Bearer"}

#Invoke webrequest
$objects = Invoke-RestMethod -Uri 'https://hr2day-9521.cloudforce.com/services/data/v56.0/query?q=SELECT+hr2d__HireDate__c,hr2d__TerminationDate__c,hr2d__EmplNr__c,hr2d__Prefix__c,hr2d__Employer__r.name,name,hr2d__Nickname__c,hr2d__RecordId__c,hr2d__TerminationDateFilter__c,hr2d__Initials__c,hr2d__EmailWork__c,Id,hr2d__A_name__c,LastModifiedDate,hr2d__FirstName__c,OwnerId,IsDeleted,hr2d__Surname__c,hr2d__DepartmentToday__c,hr2d__JobToday__c,hr2d__Employer__c,hr2d__ArbeidsrelatieToday__c+FROM+hr2d__Employee__c' -Method get -headers $authorizationheader

$objects | ConvertTo-Json

$data = $objects.records

$users = $data



# database connector built
$SqlConn    = New-Object System.Data.SqlClient.SqlConnection
$SqlCmd     = new-object System.Data.SqlClient.SQLcommand 
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter 

$SqlConn.ConnectionString = "Server=$sqlServer;Database=$sqlDBName;User=$sqlAdmin;Password=$sqlPassword;Integrated Security=true;" 
$SqlCmd.Connection = $SqlConn 
$SqlConn.Open()


#Get User information
foreach($user in $users) {
#If($user.hr2d__EmplNr__c){
    $EmployeeID            = $user.hr2d__EmplNr__c
    $Firstname             = $user.hr2d__FirstName__c
    $Lastname              = $user.hr2d__Surname__c.Replace("'", "''")
    $Employer              = $user.hr2d__Employer__r.Name
    $HR2Day_Id             = $user.Id
    $OwnerId               = $user.OwnerId
    $IsDeleted             = $user.IsDeleted
    $Hr2DayName            = $user.Name.Replace("'", "''")
    #$LastModifiedDate      = $user.LastModifiedDate
    $Employer_Number       = $user.hr2d__Employer__c
    $HireDate              = $user.hr2d__HireDate__c
    $Initials              = $user.hr2d__Initials__c
    $TerminationDate       = $user.hr2d__TerminationDate__c 
    $Nickname              = $user.hr2d__Nickname__c
    $prefix                = $user.hr2d__Prefix__c
    #$Lastname             = ($prefix +" " +$lastname).Replace('  ',' ')
    $fullName              = $user.hr2d__A_name__c.Replace("'", "''") 
    $EmailWork             = $user.hr2d__EmailWork__c
    $HR2Day_RecordId       = $user.hr2d__RecordId__c
    $TerminationDateFilter = $user.hr2d__TerminationDateFilter__c
    $DepartmentID          = $user.hr2d__DepartmentToday__c
    $JobID                 = $user.hr2d__JobToday__c
    $ArbeidsRelatieID      = $user.hr2d__ArbeidsrelatieToday__c

    
    
    
  
 # set sql query Update to db:
    $SqlUpdate = "
    UPDATE $sqlDBTable 
       SET [EmployeeID]             = '$EmployeeID'
          ,[Firstname]              = '$Firstname'
          ,[Lastname]               = '$Lastname'
          ,[Employer]               = '$Employer'
          ,[HR2Day_Id]              = '$HR2Day_Id'
          ,[OwnerId]                = '$OwnerId'
          ,[IsDeleted]              = '$IsDeleted'
          ,[Hr2DayName]             = '$Hr2DayName'
          ,[LastModifiedDate]       = '$LastModifiedDate'
          ,[Employer_Number]        = '$Employer_Number'
          ,[HireDate_date]          = '$HireDate'
          ,[HireDate_text]          = '$HireDate'
          ,[Initials]               = '$Initials'
          ,[TerminationDate]        = '$TerminationDate'
          ,[Nickname]               = '$Nickname'
          ,[prefix]                 = '$prefix'
          ,[EmailWork]              = '$EmailWork'
          ,[HR2Day_RecordId]        = '$HR2Day_RecordId'
          ,[TerminationDateFilter]  = '$TerminationDateFilter'
          ,[DepartmentID]           = '$DepartmentID'
          ,[JobID]                  = '$JobID'
          ,[ArbeidsRelatieID]       = '$ArbeidsRelatieID'
          
     WHERE HR2Day_Id = '$HR2Day_Id'
    "
  
  # set sql query Add to db:
    $SqlInsert = "
    INSERT INTO $sqldbTable ( [EmployeeID], [Firstname], [Lastname], [Employer], [HR2Day_Id], [OwnerId], [Hr2DayName], [LastModifiedDate], [Employer_Number], [HireDate_date], [Initials], [TerminationDate], [Nickname], [prefix], [EmailWork], [HR2Day_RecordId], [TerminationDateFilter], [HireDate_text], [DepartmentID], [JobID], [ArbeidsRelatieID] )
                   VALUES ('$EmployeeID','$Firstname','$Lastname','$Employer','$HR2Day_Id','$OwnerId','$Hr2DayName','$LastModifiedDate','$Employer_Number','$HireDate','$Initials','$TerminationDate','$Nickname','$prefix','$EmailWork','$HR2Day_RecordId','$TerminationDateFilter','$HireDate','$DepartmentID','$JobID','$ArbeidsRelatieID')
    "
 # set SQLQuery Select specific
    $SqlQuery = "
    SELECT HR2Day_Id FROM $sqlDBTable 
    WHERE HR2Day_Id = '$HR2Day_Id'
    " 
  

# check if record exists
$sqlDataSet1 = New-Object System.Data.DataSet 
$SqlCmd.Commandtext = $SqlQuery 
$SqlAdapter.SelectCommand = $SqlCmd 
$SqlAdapter.Fill($sqlDataSet1) >> $null
 
 

if ($sqlDataSet1.Tables.HR2Day_Id) {
    # update record
    $sqlDataSet2 = New-Object System.Data.DataSet 
    $SqlCmd.Commandtext = $SqlUpdate
    $SqlAdapter.SelectCommand = $SqlCmd 
    $SqlAdapter.Fill($SQLDataSet2) >> $null
    Write-Host "record updated for $HR2Day_Id"
    }
else {
    # insert record
    $sqlDataSet3 = New-Object System.Data.DataSet 
    $SqlCmd.Commandtext = $SqlInsert
    $SqlAdapter.SelectCommand = $SqlCmd 
    $SqlAdapter.Fill($SQLDataSet3) >> $null
    Write-Host "record added for $HR2Day_Id"
    }
}


# check and delete records

$SqlQuery_all = "
SELECT HR2Day_Id FROM $sqlDBTable 
" 

# set dataset
$sqlDataSet4 = New-Object System.Data.DataSet
$SqlCmd.Commandtext = $SqlQuery_all 
$SqlAdapter.SelectCommand = $SqlCmd 
$SqlAdapter.Fill($sqlDataSet4) >> $null


$usrarray = $users.hr2d__RecordId__c

$sqlArray = $null
foreach($entry in $sqlDataSet4.Tables) {
    $sqlArray += $entry.HR2Day_Id
    }

# compare csv to sql, check for deletes
if($sqlArray) {
    Compare-Object $sqlArray $usrArray -IncludeEqual | 
    foreach  { 
        if ($_.sideindicator -eq '<=') {$deletes += $_.InputObject}
        }
    }


#delete from SQL
if($deletes) {
    foreach($user in $deletes) {
        # set sql query
        $SqlDelete = "
        DELETE FROM $sqlDBTable 
        WHERE EmployeeID = '$user'
        "
        # delete record
        $sqlDataSet5 = New-Object System.Data.DataSet
        $SqlCmd.Commandtext = $SqlDelete
        $SqlAdapter.SelectCommand = $SqlCmd 
        $SqlAdapter.Fill($SQLDataSet5) >> $null
        Write-Host "record deleted for $user"
        $deleted ++
        }
    }
 
    

#sql close
$SqlConn.Close() 