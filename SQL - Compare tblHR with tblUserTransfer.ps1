#---------------------------------------------
# SQL - Compare tbl1 with tbl2
# HAB 23-04-2024
# v.1.0
#
#---------------------------------------------


# Database parameters
$sqlServer = "<SQLServer>"
$sqlDBName = "<SQLDbname>"
$sqlDBUser = "<SQLUser>"
$sqlDBPass = "<SQLPasswor>"

# Tables names
$tbl1 = "<tbl1>"
$tbl2 = "<tbl2>

# UserID
$userIdToCompare = "<UserId>"

# Build SQL connection 
$sqlConnString = "Server=$sqlServer;Database=$sqlDBName;User=$sqlDBUser;Password=$sqlDBPass;"
$sqlConn = New-Object System.Data.SqlClient.SqlConnection($sqlConnString)
$sqlConn.Open()

# SQL query to compare data between tbl1 and tbl2 for a specific user
$sqlQuery = @"
   SELECT
        t.Userid,
        t.Managerid,
        t.Department,
        t.Location,
        t.JobTitle,
        t.Company,
        v.Userid as ViewUserid,
        v.Managerid as ViewManagerid,
        v.Department as ViewDepartment,
        v.Location as ViewLocation,
        v.Title as ViewTitle,
        v.Company as ViewCompany
    FROM
        $tbl1 t
    FULL OUTER JOIN
        $tbl2 v
    ON
        t.Userid = v.Userid AND
        t.Managerid = v.managerID AND
        t.Department = v.Department AND
        t.Location = v.Location AND
        t.JobTitle = v.Title AND
        t.Company = v.Company
    WHERE
        t.UserId = '$userIdToCompare' OR v.UserId = '$userIdToCompare'
"@

#SQL query
$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlCmd.Connection = $sqlConn
$sqlCmd.CommandText = $sqlQuery
$reader = $sqlCmd.ExecuteReader()

# Output results compare
while ($reader.Read()) {
    $userid = $reader["Userid"]
    $manager = $reader["Manager"]
    $department = $reader["Department"]
    $location = $reader["Location"]
    $jobTitle = $reader["JobTitle"]
    $company = $reader["Company"]
    $viewUserid = $reader["ViewUserid"]
    $viewManager = $reader["ViewManager"]
    $viewDepartment = $reader["ViewDepartment"]
    $viewLocation = $reader["ViewLocation"]
    $viewJobTitle = $reader["ViewJobTitle"]
    $viewCompany = $reader["ViewCompany"]

    if ($userid -eq $null) {
        Write-Host "Userid $viewUser exists only in the view."
    } elseif ($viewUserid -eq $null) {
        Write-Host "Userid $userid exists only in tbl1."
    } elseif ($userid -ne $viewUserid -or $manager -ne $viewManager -or $department -ne $viewDepartment -or $location -ne $viewLocation -or $jobTitle -ne $viewJobTitle -or $company -ne $viewCompany) {
        Write-Host "Data does not match for userid $userid."
        Write-Host "tbl1: $userid, $manager, $department, $location, $jobTitle, $company"
        Write-Host "combined_view: $viewUserid, $viewManager, $viewDepartment, $viewLocation, $viewJobTitle, $viewCompany"
    } else {
        Write-Host "Data does match for userid $userid."
    }
}

# Close the SQL connection
$sqlConn.Close()
