#----------------------------------------------
# VM - Clone VM from Template
# v1.0 by HAB 12-10-2021
# This script will create a VM with the input  
# of the xml file.
# v1.5
# 14-03-2022 Added loop to check if VM Exists
#----------------------------------------------


# Enable Verbose in script
$oldverbose = $VerbosePreference
$VerbosePreference = "continue"

# Variables created by Parameters from Ivanti Automation.
# Make sure the variable vCenterURL, vCenterUsername and vCenterPassword are created as Variables in Ivanti Automation

$vCenterURL = "$[vCenter URL]"
$vCenterUsername = "$[vCenter administrator]"
$vCenterPassword = "$[vCenter administrator password]"
$ConnectError = ""

# Check if vCenter variables are available

if (!$vCenterURL -or !$vCenterUsername -or !$vCenterPassword){
    $host.UI.WriteErrorLine("vCenter URL and credentials are needed in order to connect to a VMware vCenter environment.")
    $Global:message = "vCenter URL and credentials are needed in order to connect to a VMware vCenter environment."
    exit 1
    }

# Check if VMware PowerCli is installed. This is function and called later in the script.

Function Check-PowerCLI {
 
   try {
        $powerCliModule = Get-InstalledModule 'VMware.PowerCLI*'
    }
   catch {
        $host.UI.WriteErrorLine('VMware module not found in installed modules. Ensure VMWare.PowerCLI version 10+ is installed on the machine.')
    $Global:message = 'VMware module not found in installed modules. Ensure VMWare.PowerCLI version 10+ is installed on the machine.'
        exit 1
    }
    if($powercliModule.Version -lt [Version]'10.0'){
        $host.UI.WriteErrorLine('VMware.PowerCLI module must be version 10 or higher.')
    $Global:message = 'VMware.PowerCLI module must be version 10 or higher.'
        exit 1
    }
        
    $pwrcli_install = (Get-Module -ListAvailable VMware.PowerCLI*).path
    $modulepaths = $env:PSModulePath

    if($modulepaths -contains $pwrcli_install){
        $host.UI.WriteErrorLine('VMware PowerCLI Module installation path not added to PSModulePath.')
    $Global:message = 'VMware PowerCLI Module installation path not added to PSModulePath.'
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
    $Global:message = $ConnectError
    exit 1
    }
}

#Function disconnect VIServer

Function ExitonError {
    Disconnect-VIServer -Server $vCenterURL
    exit 1
    }

# Check if Vmware.PowerCLI is installed
Check-PowerCLI

# Connect to vCenter
Connect-vCenter


# Create vCenter OS Customization Profile

# All required variables for creating Customization Profile and Create VM from Template resolved from Ivanti Automation
# Get the IP information from the first NIC and convert to IP Address and SubnetMask
# Convert the DNS information in the correct format

$NicInfo = "$[ServerNics]" -split(";")
$FirstNic = $NicInfo[0] -split(",")

$IPAddress =$FirstNic[0].Trim()
$Subnetmask = $FirstNic[1].Trim()
$IPv4Gateway = "$[IPGateway]"

$DNS = "$[DNS]" -split(",")

$DNS_Count = $DNS.Count
$DNS1 = $DNS[0].Trim()
$DNS2 = $DNS[1].Trim()

# Create Local and Domain Credentials
$LocalUsername = "^[Local_Admin]"
#$LocalPassword = ConvertTo-SecureString "^[Local_admin_pw]" -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($LocalUsername)
Write-Verbose "Local Credentials created"

$DomainUsername = "^[Domain_Admin]"
$DomainPassword = ConvertTo-SecureString "^[Domain_Admin_Pw]" -AsPlainText -Force
$DomainCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($DomainUsername, $DomainPassword)
Write-Verbose "Domain Credentials created"

# Create parameters for OSCustomization

$osParam = @{
    Name = 'VMSpec1' 
    OSType = 'Windows'
    Changesid = $true
    TimeZone = '$[Timezone]'
    OrgName = '$[Folder]'
    FullName = '$[LocalUsername]'
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

$Template_Name = "$[Template]"
$VMServerName = "$[ServerName]"
$Datacenter = "$[DataCenter]"
$Specification = $osParam.Name
$Datastore = "$[DataStore]"
$VMCluster = "$[ComputeCluster]"

# Check all variables and if values exists in vCenter

# Check if VM ServerName exists
$VirtualMachine = Get-VM -Name $VMServerName -ErrorVariable ConnectError -ErrorAction SilentlyContinue

if ($VirtualMachine){
    $Host.UI.WriteErrorLine("A VM with name `"$VMServerName`" already exists")
    $Global:message = "A VM with name `"$VMServerName`" already exists"
    Disconnect-VIServer
    }
else {
    $myNewName = $VMServerName}

# Check if Template exists
$myTemplate = Get-Template -Name $Template_Name -location $datacenter -ErrorAction stop

if (!$myTemplate){
    $Host.UI.WriteErrorLine("A template with name `"$Template_Name`" does not exist.")
    $Global:message = "A template with name `"$Template_Name`" does not exist."
    ExitonError
}

# Check if Datastore exists 

 $myDatastore = Get-Datastore -Name $Datastore -ErrorAction stop

 if (!$myDatastore){
     $host.UI.WriteErrorLine("A datastore with name `"$Datastore`" does not exist.")
     $Global:message = "A datastore with name `"$Datastore`" does not exist."
     ExitonError
     exit 1
 }

 # Check if OS Customization exists

  $mySpecification = Get-OSCustomizationSpec -Name $Specification -ErrorAction stop
if (!$mySpecification){
    $Host.UI.WriteErrorLine("A Configuration Specification with name `"$Specification`" does not exist.")
    $Global:message = "A Configuration Specification with name `"$Specification`" does not exist."
    ExitonError
}

# Check if Cluster exists

$MyResourcePool = Get-Cluster -Name $VMCluster -ErrorAction stop
    if (!$MyResourcePool){
        $Host.UI.WriteErrorLine("A Cluster with name `"$VMCluster`" does not exist.")
        $Global:message = "A Cluster with name `"$VMCluster`" does not exist."
        ExitonError
    }

# Create New-VM command

$command = "New-VM "
if ($myNewName){$command += "-Name `"$myNewName`" "}
if ($myTemplate){$command += '-Template $myTemplate '}
if ($myVMHOST){$command += "-VMHOST `"$myVMHOST`" "}
if ($myResourcePool){$command += "-ResourcePool `"$myResourcePool`" "}
if ($mySpecification){$command += "-OSCustomizationSpec `"$mySpecification`" "}
if ($myDatastore){$command += "-Datastore `"$myDatastore`" "}
$command += " -ErrorAction stop -ErrorVariable ConnectError"
$Result =$null

Write-Verbose $command

# Start Create VM from Template

try{
    $result = invoke-expression $command
}
catch{
    if ($ConnectError.count -gt 1){
        $ConnectErmsg = $ConnectError[0].message
    }
    else{
        $ConnectErmsg = $ConnectError.message
    }
    $ConnectErmsg = $ConnectErmsg.Substring($ConnectErmsg.IndexOf("New-VM")+8)

    if($ConnectErmsg.contains(': "')){
        $ConnectErmsg = ($ConnectErmsg.Substring($ConnectErmsg.IndexOf(': "')).replace(': ',"")).replace('"',"")
    }
    $host.UI.WriteErrorLine($ConnectErmsg)
    }
    
Do { 
    $vm = get-vm -name "$[ServerName]" -ErrorAction SilentlyContinue
    Start-Sleep -s "30"
        }
    Until ($VM.name -eq "$[ServerName]") -count 5 

#$vm = get-vm -name "$[ServerName]"
        
$clientfolder = get-folder -name "$[Folder]" -type vm -location $datacenter

Move-VM -VM $vm -Destination $vm.VMHost -InventoryLocation $clientfolder	

# Close vCenter connection
Disconnect-VIServer -Server $vCenterURL

$VerbosePreference = $oldverbose