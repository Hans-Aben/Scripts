$verbosePreference = "Continue" 

try
{
    #  Pre-requisite checks
    #  Check the VMWare PowerCli Module has been installed.
    $powerCliModule = Get-InstalledModule 'VMware.PowerCLI*' -ErrorAction Stop

    #  Check version compatibility
    if($powercliModule.Version -lt [Version]'10.0')
    {
        throw 'VMware.PowerCLI module must be version 10 or higher.'
    }

    #  ** Test with customer **
    #  TestEnv works without the module added to PSModulePath

    #$pwrcli_install = (Get-Module -ListAvailable VMware.PowerCLI*).path;
    #$modulepaths = $env:PSModulePath;

    #if($modulepaths -notcontains $pwrcli_install) #  Changed operator from -contains to --notcontains
    #{
    #    throw 'VMware PowerCLI Module installation path not added to PSModulePath.'
    #}


    #  Define input variables
    $vCenterURL = "$[vCenter URL]"
    $vCenterUsername = "$[vCenter administrator]"
    $vCenterPassword = ConvertTo-SecureString "$[vCenter administrator password]" -AsPlainText -Force
    $Template_Name = "$[Template]"
    $VMServerName = "$[ServerName]"
    $Datacenter = "$[DataCenter]"
    $Datastore = "$[DataStore]"
    $VMCluster = "$[ComputeCluster]"
    $folderName = "$[Folder]"
    $NicInfo = "$[ServerNics]" -split(";")
    $FirstNic = $NicInfo[0] -split(",")
    $IPAddress = $FirstNic[0].Trim()
    $Subnetmask = $FirstNic[1].Trim()
    $IPv4Gateway = "$[IPGateway]"
    $DNS = "$[DNS]" -split(",")
    $DNS1 = $DNS[0].Trim()
    $DNS2 = $DNS[1].Trim()
    $LocalUsername = "^[Local_Admin]"
    $DomainUsername = "^[Domain_Admin]"
    $DomainPassword = ConvertTo-SecureString "^[Domain_Admin_Pw]" -AsPlainText -Force
    $LocalCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($LocalUsername)
    $DomainCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($DomainUsername, $DomainPassword)
    $vcenterCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ($vCenterUsername, $vCenterPassword)

    $viServer = $null


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



    # Check if vCenter variables are available
    if (!$vCenterURL -or !$vCenterUsername -or !$vCenterPassword)
    {
        throw "vCenter URL and credentials are needed in order to connect to a VMware vCenter environment."
    }


    # Do not display Deprecation Warnings and ignore Invalid Certificates in this PowerCLI session
    Set-PowerCLIConfiguration -DisplayDeprecationWarnings $false -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | out-null


    # Connect to vCenter
    $viServer = connect-viserver -Server $vCenterURL -Credential $vcenterCredential -ErrorAction Stop
    if(!$viServer.IsConnected)
    {
        throw "$viServer unavailable"
    }


    # Check if OSCustomization already exists and remove and create new OS Customization Profile
    if ((Get-OSCustomizationSpec -server $viServer -ErrorAction Stop).Name -eq $osParam.Name)
    {
        Remove-OSCustomizationSpec  $osParam.Name -server $viServer -Confirm:$false -ErrorAction Stop  | out-null
        Write-Verbose "$(get-date -f  "dd/MM/yyyy hh:mm:ss")`tOld OS Customization found and removed."
    }

    New-OSCustomizationSpec @osParam -ErrorAction Stop  | out-null
    Write-Verbose "$(get-date -f  "dd/MM/yyyy hh:mm:ss")`tNew OS Customization has been created. Name of OS Customization is:  $($osParam.Name)"


    # Check OSCustomization NIC Mapping because a default is creating during OSCustomizationSpec command.
    # This is only a DHCP option which is not needed.  When creating a new OSCustomiationNicMapping a new profile is created.
    # By removing the current OSCustomizationNicMapping profiles we prevent issues during creating a VM from Template.
    $nicMapping = Get-OSCustomizationSpec $osParam.Name -server $viServer -ErrorAction Stop | Get-OSCustomizationNicMapping -server $viServer -ErrorAction Stop


    if(![string]::IsNullOrEmpty($nicMapping)) # $nicMapping contains something.
    {
        Remove-OSCustomizationNicMapping $nicMapping -Confirm:$false -ErrorAction Stop | out-null
    }
    New-OSCustomizationNicMapping -server $viServer -OSCustomizationSpec $osParam.Name -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $Subnetmask -DefaultGateway $IPv4Gateway -Dns "$DNS1", "$DNS2" -ErrorAction Stop  | out-null
    $Specification = $osParam.Name



    # Check if VM already exists
    $VirtualMachine = Get-VM -Name $VMServerName -server $viServer -ErrorAction SilentlyContinue

    if ($VirtualMachine)
    { 
        throw "A VM with name `"$VMServerName`" already exists"
    }
    


    # Check if Template exists
    $myTemplate = Get-Template -Name $Template_Name -location $datacenter -server $viServer -ErrorAction silentlycontinue

    #  Check to see if multiple templates are returned.  Could result in an ambiguious request.
    if ($myTemplate.Count -gt 1)
    {
        throw "Multiple templates exist with `"$Template_Name`""
    }

    #  Allow to enter if and throw custom exception (or remove completely and set to erroraction stop above).new-
    if (!$myTemplate) # Change to be a more explicit check
    {
        throw "A template with name `"$Template_Name`" does not exist."
    }


    # Check if Datastore exists
    $myDatastore = Get-Datastore -Name $Datastore -server $viServer -ErrorAction silentlycontinue

    if (!$myDatastore) # Change to be a more explicit check
    { 
        throw "A datastore with name `"$Datastore`" does not exist."
    }


    # Check if OS Customization exists
    $mySpecification = Get-OSCustomizationSpec -Name $Specification -server $viServer -ErrorAction silentlycontinue

    if (!$mySpecification)  # Change to be a more explicit check
    {
        throw "A Configuration Specification with name `"$Specification`" does not exist."
    }


    # Check if Cluster exists
    $myResourcePool = Get-Cluster -Name $VMCluster -server $viServer -ErrorAction silentlycontinue

    if (!$myResourcePool)  # Change to be a more explicit check
    {
        throw "A Cluster with name `"$VMCluster`" does not exist."
    }


    # Clone a VM from template
    New-VM -Name $VMServerName `
            -Template $myTemplate `
            -ResourcePool $myResourcePool `
            -OSCustomizationSpec $mySpecification `
            -Datastore $myDatastore `
            -Server $viServer `
            -ErrorAction stop  | out-null

    
    #  Unlikely, however if there is any possibility of a delay from the New-VM cmdlet or the vm record isn't immediately available, 
    #  then we need to add a check until the new vm becomes available before continuing.

    #  check to see if the new vm record is available
    $vm = get-vm -name $VMServerName -server $viServer -ErrorAction Continue
    if ([string]::IsNullOrEmpty($vm))
    {
        #  Enter retry loop 2 x 5 seconds
        $i=0
        do
        {
            sleep 5 
            $vm = get-vm -name $VMServerName -server $viServer -ErrorAction Continue
            $i++
        
        }
        until ($vm.Name -eq $VMServerName -or $i -eq 2) # VM is available or 10 seconds have elapsed.

        # Timed out, throw exception.
        if ($i -eq 2) 
        {
            throw "Unable to retrieve Cloned VM."
        }
    }



    # Move the VM to destination folder. 
    $clientfolder = get-folder -name $folderName -type vm -server $viServer -ErrorAction Stop
    
    if (!$clientfolder)
    {
        throw "A Folder with name `"$folderName`" does not exist."
    }
    Move-VM -VM $vm -Destination $vm.VMHost -InventoryLocation $clientfolder -server $viServer -ErrorAction Stop | out-null
    Write-Verbose "$(get-date -f  "dd/MM/yyyy hh:mm:ss")`tVM successfully moved to $clientFolder"

}
catch
{
    $Host.UI.WriteErrorLine($_)
    $Global:message = $_.Exception.Message
    exit 1

}
finally
{
    if($viServer.IsConnected)
    {
        Disconnect-VIServer -Server $viServer -confirm:$false
        Write-Verbose "$(get-date -f  "dd/MM/yyyy hh:mm:ss")`tConnection state = $($viServer.IsConnected) "
    }

}