# Enable Verbose in script
$oldverbose = $VerbosePreference
$VerbosePreference = "continue"

# Variables created by Parameters from Ivanti Automation.
# Make sure the variable vCenterURL, vCenterUsername and vCenterPassword are created as Variables in Ivanti Automation

$vCenterURL = "<V-centerUL>"
$vCenterUsername = "<vcenter username>"
$vCenterPassword = "<password>"
$ConnectError = ""

# Check if vCenter variables are available

if (!$vCenterURL -or !$vCenterUsername -or !$vCenterPassword){
    $host.UI.WriteErrorLine("vCenter URL and credentials are needed in order to connect to a VMware vCenter environment.")
    exit 1
    }

# Check if VMware PowerCli is installed. This is function and called later in the script.

Function Check-PowerCLI {
 
   try {
        $powerCliModule = Get-InstalledModule 'VMware.PowerCLI*'
    }
   catch {
        $host.UI.WriteErrorLine('VMware module not found in installed modules. Ensure VMWare.PowerCLI version 10+ is installed on the machine.')
        exit 1
    }
    if($powercliModule.Version -lt [Version]'10.0'){
        $host.UI.WriteErrorLine('VMware.PowerCLI module must be version 10 or higher.')
        exit 1
    }
        
    $pwrcli_install = (Get-Module -ListAvailable VMware.PowerCLI*).path
    $modulepaths = $env:PSModulePath

    if($modulepaths -contains $pwrcli_install){
        $host.UI.WriteErrorLine('VMware PowerCLI Module installation path not added to PSModulePath.')
    }
}

# Connect vCenter. This function is called later in the script.

Function Connect-vCenter {
    # Do not display Deprecation Warnings and ignore Invalid Certificates in this PowerCLI session
    $certificationSET = Set-PowerCLIConfiguration -DisplayDeprecationWarnings $false -InvalidCertificateAction Ignore -Scope Session -Confirm:$false

    # Connect to vCenter with the provided information.
    try{
    $VIconnection = Connect-VIServer -Server $vCenterURL -Username $vCenterUsername -Password $vCenterPassword -ErrorVariable ConnectError -ErrorAction Stop
    Write-Verbose "Connection to vCenter $global:DefaultVIServer succeeded"
    }
    catch{
    $ConnectError = $ConnectError.message
    $ConnectError = $ConnectError.Substring($ConnectError.IndexOf("Connect-VIServer")+18)
    $host.UI.WriteErrorLine($ConnectError)
    exit 1
    }
}

# Check if Vmware.PowerCLI is installed
Check-PowerCLI

# Connect to vCenter
Connect-vCenter

# Create vCenter OS Customization Profile

# All required variables for creating Customization Profile and Create VM from Template resolved from Ivanti Automation
# Get the IP information from the first NIC and convert to IP Address and SubnetMask
# Convert the DNS information in the correct format

$NicInfo = "i.p.,255.255.255.0
" -split(";")
$FirstNic = $NicInfo[0] -split(",")

$IPAddress =$FirstNic[0].Trim()
$Subnetmask = $FirstNic[1].Trim()
$IPv4Gateway = "Gateway"

$DNS = "DNS
" -split(",")

$DNS_Count = $DNS.Count
$DNS1 = $DNS[0].Trim()
$DNS2 = $DNS[1].Trim()

# Create Local and Domain Credentials
$LocalUsername = "Administrator"
$LocalPassword = ConvertTo-SecureString "<password>" -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($LocalUsername, $LocalPassword)
Write-Verbose "Local Credentials created"

$DomainUsername = "iconcr\abenh_admin"
$DomainPassword = ConvertTo-SecureString "<password>" -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($DomainUsername, $DomainPassword)
Write-Verbose "Domain Credentials created"

# Create parameters for OSCustomization

$osParam = @{
    Name = 'VMSpec1' 
    OSType = 'Windows'
    Changesid = $true
    TimeZone = '015'
    OrgName = 'Testing'
    FullName = 'Administrator'
    AdminPassword =$LocalCred
    Domain = "<domain>"
    DomainCredentials = $DomainCred
    Type = 'NonPersistent'
}

# Check if OSCustomization already exists and remove and create new OS Customization Profile

If ((Get-OSCustomizationSpec).Name -eq $osParam.Name){
    Remove-OSCustomizationSpec $osParam.Name -Confirm:$false
    New-OSCustomizationSpec @osParam
    Write-Verbose "Old OS Customizations are removed and a new OS Customization is created. Name of OS Customization is: $osParam.Name"
    }
Else{
    New-OSCustomizationSpec @osParam
    }

# Check OSCustomization NIC Mapping because a default is creating durin OSCustomizationSpec command.
# This is only a DHCP option which is not needed. When creating a new OSCustomiationNicMapping a new profile is created.
# By removing the current OSCustomizationNicMapping profiles we prevent issues during creating a VM from Template.

$nicMapping = Get-OSCustomizationSpec $osParam.Name | Get-OSCustomizationNicMapping

If($nicMapping -ne $Null){
    Remove-OSCustomizationNicMapping $nicMapping -Confirm:$false
    New-OSCustomizationNicMapping -OSCustomizationSpec $osParam.Name -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $Subnetmask -DefaultGateway $IPv4Gateway -Dns "$DNS1", "$DNS2"
    }
Else{
    New-OSCustomizationNicMapping -OSCustomizationSpec $osParam.Name -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $Subnetmask -DefaultGateway $IPv4Gateway -Dns "$DNS1", "$DNS2"
    }

# Create all Create from Template variables which are filled by Ivanti Automation parameters

$Template_Name = "<Template>"
$VMServerName = "<VMServernam>"
$Datacenter = "EUDC"
$Specification = $osParam.Name
$Datastore ="<Datestore>"
$VMCluster = "<Cluster>"

# Check all variables and if values exists in vCenter

# Check if VM ServerName exists
$VirtualMachine = Get-VM -Name $VMServerName -ErrorVariable ConnectError -ErrorAction SilentlyContinue

if ($VirtualMachine){
    $Host.UI.WriteErrorLine("A VM with name `"$VMServerName`" already exists");exit 1
    }
else {
    $myNewName = $VMServerName}

# Check if Template exists
$myTemplate = Get-Template -Name $Template_Name -ErrorAction SilentlyContinue

if (!$myTemplate){
    [array]$availableTemplates = (Get-Template -ErrorAction SilentlyContinue).Name
    $Host.UI.WriteErrorLine("A template with name `"$Template_Name`" does not exist.")
    exit 1
}

# Check if Datacenter exists
$MyDatacenter = Get-Datacenter -Name $Datacenter -ErrorAction SilentlyContinue

if (!$MyDatacenter){
    [array]$availableDatacenters = (Get-DataCenter -ErrorAction SilentlyContinue).Name
    $Host.UI.WriteErrorLine("A DataCenter with name `"$Datacenter`" does not exist.")
    exit 1
}

# Check if Datastore exists

 $myDatastore = Get-Datastore -Name $Datastore -ErrorAction SilentlyContinue

 if (!$myDatastore){
     [Array]$AvailableDatastores = Get-Datastore -ErrorAction SilentlyContinue
     $host.UI.WriteErrorLine("A datastore with name `"$Datastore`" does not exist.")
     exit 1
 }

 # Check if OS Customization exists

  $mySpecification = Get-OSCustomizationSpec -Name $Specification -ErrorAction SilentlyContinue
 if (!$mySpecification){
    [array]$AvailableSpecifications = (Get-OSCustomizationSpec -ErrorAction SilentlyContinue).Name
    $Host.UI.WriteErrorLine("A Configuration Specification with name `"$Specification`" does not exist.")
    exit 1
}

 # Get ResourcePool from Datacenter
 $DCResourcePools = Get-ResourcePool -Location $MyDatacenter | Where-Object {$_.Parent.Name -eq $VMCluster} | Select *
 $myResourcePool = $DCResourcePools.Name

 if(!$myResourcePool){
    [array]$AvailableResourcePools = (Get-ResourcePool -ErrorAction SilentlyContinue).Name
    $Host.UI.WriteErrorLine("No Resource Pools are found.")
    exit 1
}



# Create New-VM command

$command = "New-VM "
if ($myNewName){$command += "-Name `"$myNewName`" "}
if ($myTemplate){$command += "-Template `"$myTemplate`" "}
if ($myResourcePool){$command += "-ResourcePool `"$VMCluster`" "}
if ($mySpecification){$command += "-OSCustomizationSpec `"$mySpecification`" "}
if ($myDatastore){$command += "-Datastore `"$myDatastore`" "}
$command += " -ErrorAction SilentlyContinue -ErrorVariable ConnectError"
$Result =$null
Write-Host $command

# Start Create VM from Template

try{
    $result = invoke-expression $command
}
catch{
    if ($ConnectError.count -eq 2){
        $ConnectError = $ConnectError[0].message
    }
    else{
        $ConnectError = $ConnectError.message
    }
    $ConnectError = $ConnectError.Substring($ConnectError.IndexOf("New-VM")+8)

    if($ConnectError.contains(': "')){
        $ConnectError = ($ConnectError.Substring($ConnectError.IndexOf(': "')).replace(': ',"")).replace('"',"")
    }
    $host.UI.WriteErrorLine($ConnectError)
    exit 1
    }


#CPU & RAM change

$VMCPU = $VMinfo.NumCpu
$VMRAM = $VMinfo.MemoryMB

$CPU = "2"
$RAM = "8192"


If($CPU -ne $VMinfo.NumCpu){
Set-VM -VM "eu-ivantit-a009" -NumCpu $CPU -Confirm:$false
Write-Verbose "The amount of CPU for $VMName is changed from $VMCPU to $CPU"
}
Else{
Write-Verbose "No changes on CPU are executed"
}



If($RAM -ne $VMinfo.MemoryMB){
Set-VM -VM "eu-ivantit-a009" -MemoryMB $RAM -Confirm:$false
Write-Verbose "The amount of RAM for $VMName is changed from $VMRAM to $RAM"
}
Else{
Write-Verbose "No changes on Memory are executed"
}

$VerbosePreference = $oldverbose