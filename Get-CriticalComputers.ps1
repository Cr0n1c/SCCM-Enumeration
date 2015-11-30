Import-Module activedirectory
Push-Location #This is for SQL
Import-Module sqlps -disablenamechecking
pop-Location
 
#Requires MSSQL to be installed or at least the powershell modules
 
<#
  [+] [AD] Machines that are Domain Controllers
  [+] [AD] Machines that are in a *server* DN
  [+] [AD] Machines that are named: *srv*, *server*, *db*, *adm*
  [+] [AD] Machines whose OS is server in nature
  [+] [AD] Machines that fall under the "Default Domain Controllers Policy" GPO
  [+] [SCCM] Machines where the primary user is a privileged user
  [+] [SCCM] Machines where the most logged in user is a privileged user
  [+] [SCCM] Machines who are running "server" applications: apache, sql server, iis
  [+] [SCCM] Machines that are not in Active Directory
  [+] [SCCM] Default Gateways
  [-] [????] Machines that server as Layer 2/3: Routers, Switches
#>
  
$global:criticalMachines = @{}
$sccmServer = 'pa-sccmdb-01'
  
Function Add-CComputer([string]$c, [string]$d){
    If ($global:criticalMachines.ContainsKey($c) -and -not $global:criticalMachines.$c.Contains($d)){
        $global:criticalMachines.$c += $d
    }ElseIf (-not $global:criticalMachines.ContainsKey($c.ToLower())){
        $global:criticalMachines.Add($c.ToLower(), @($d))
    }
}
  
Function Set-ADCComputers{
    [xml]$report = Get-GPOReport -Guid 6ac1786c-016f-11d2-945f-00c04fb984f9 -ReportType Xml -ErrorAction Stop
    [array]$ddcpSom = $report.GPO.LinksTo.SomPath
     
    ForEach ($comp in $activeComps){
        #Distinguished Name query looking for DCs or Servers
        If ("OU=Domain Controllers" -in $comp.DistinguishedName){
            Add-CComputer $comp.Name "Member of Domain Controllers"
        }ElseIf ("Server" -in $comp.DistinguishedName){
            Add-CComputer $comp.Name "Contains 'server' in DN"
        }
         
        #SamAccountName filter search  
        $nameFilter = @("srv", "server", "db", "adm", "test", "prod", "dev", "sql")
        ForEach ($filter in $nameFilter){
            If ($comp.SamAccountName -match $filter){
                Add-CComputer $comp.Name "Contains $filter in Name"
            }
        }
  
        #Operating System query looking for server OS
        $osFilter = @("Windows XP", "Windows 7", "Vista", "Windows 10", "Windows 8", "Mac OS X", "Workstation", "Ubuntu")
        $foundMatch = $false
        ForEach ($filter in $osFilter){
            If ($comp.OperatingSystem -match "$filter"){
                $foundMatch = $true
            }
        }
         
        If (-not $foundMatch){
            Add-CComputer $comp.Name "Computer is not a User OS"
        }
  
        #Checking to see if computer is using GPO: "Default Domain Controllers Policy"
        ForEach ($filter in $ddcpSom){
            If ($comp.CanonicalName -match $filter){
                Add-CComputer $comp.Name "Computer uses Default Domain Controller Policy"
            }
        }
    }
}
  
$adComps = Get-ADComputer -Filter {enabled -eq 'true'} -Properties * #Will change the * to only fields I need when done
$activeComps = @()
$today = Get-Date
  
ForEach ($c in $adComps){
    Try{
        [datetime]$lastUpdate = $c.PasswordLastSet
    }Catch [system.exception]{
        continue
    }
  
    $daysSinceUpdate = (New-TimeSpan -Start $lastUpdate -End $today).Days
    If ($daysSinceUpdate -lt 30){ #Using default 30 days.  Need to find where this is set
        $activeComps += $c
    }
}
  
Set-ADCComputers
  
Function Set-SQLcmd($cmd){
    return Invoke-SQlcmd -query "$cmd" -database "CM_PAL" -server $sccmServer
}
  
#Create array of Active Machines in SCCM (Active = last 30 days)
$activeSCCM = Set-SQLcmd "SELECT DISTINCT LOWER(SY.Netbios_Name0) Netbios_Name0 FROM v_R_System SY JOIN
        v_AgentDiscoveries A ON A.ResourceId = SY.ResourceID WHERE A.AgentName =
        'Heartbeat Discovery' AND A.AgentTime >= DATEADD(month, -1, GETDATE())"
  
#Finding all Default Gateways
$defGWs = Set-SQLcmd "SELECT DISTINCT DefaultIPGateway0 FROM v_GS_NETWORK_ADAPTER_CONFIGUR
        WHERE IPEnabled0='1' AND DefaultIPGateWay0 NOT LIKE ('%:%') AND DefaultIPGateWay0
        NOT LIKE ('0.0.0.0') AND DefaultIPGateWay0 NOT LIKE ('127.0.0.1') AND
        DefaultIPGateWay0 IS NOT Null"
  
ForEach ($comp in $defGWs){
    Add-CComputer $comp "This is a Default Gateway"
}
  
#Finding all computers that are not in AD but are in SCCM
ForEach ($comp in $activeSCCM){
    If ($comp.Netbios_Name0.ToLower() -notin $global:criticalMachines.Keys){
        Add-CComputer $comp.Netbios_Name0.ToLower() "Computer not in Active Directory"
    }
}
  
#$privUsers came from $global:privyUsers from Get-PrivyUsers.ps1
$privUsers = $global:privyUsers
#Finding all machines where priv user is "primary users"
$pUserComputer = Set-Sqlcmd "SELECT DISTINCT LOWER(VRU.User_Name0) User_Name0, LOWER(VRS.Name0) Name0 FROM v_UsersPrimaryMachines
        UPM JOIN v_R_User VRU on UPM.UserResourceID = VRU.ResourceID JOIN v_R_System VRS ON
        UPM.MachineID = VRS.ResourceID"
  
ForEach ($row in $pUserComputer){
    If ($row.User_Name0 -in $privUsers.keys.tolower() -and $row.Name0 -in $activeSCCM.Netbios_Name0){
        Add-CComputer $row.Name0 "Primary user is a privileged user"
    }
}
  
#Finding machines where privelege users is the most active user
$pUserMostActive = Set-Sqlcmd "SELECT DISTINCT LOWER(CM.Name) Computer, LOWER(GS.TopConsoleUser0) Username FROM
        v_GS_SYSTEM_CONSOLE_USAGE_MAXGROUP GS JOIN CollectionMembers CM ON GS.ResourceID = CM.MachineID
        WHERE GS.TotalConsoleUsers0 > 1"
  
ForEach ($row in $pUserMostActive){
    $user = $row.Username.Split('\')[-1]
    If ($user -in $privUsers.keys.tolower() -and $row.Computer -in $activeSCCM.Netbios_Name0){
        Add-CComputer $row.Computer "Most active user is a privileged user"
    }
}
  
#Finding machines running "server" applications
$serverApps = Set-Sqlcmd "SELECT DISTINCT GS.Name0 FROM [SCCM_Ext].[vex_GS_CCM_RECENTLY_USED_APPS] VEX
        JOIN [V_GS_SYSTEM] GS ON GS.[ResourceID] = VEX.[ResourceID] WHERE (VEX.ExplorerFileName0 = 'rdpclip.exe'
        OR VEX.ExplorerFileName0 Like 'sqlservr%' OR VEX.ExplorerFileName0 Like 'w3wp%')"
  
ForEach ($row in $serverApps){
    If ($row.Name0 -in $activeSCCM.Netbios_Name0){
        Add-CComputer $row.Name0 "Computer is running a server application"
    }
}
 
 
#global:critcalMachines contains all the data that we care about
