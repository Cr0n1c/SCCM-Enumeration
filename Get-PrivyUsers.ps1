Import-Module activedirectory #Not default, must install
Import-Module grouppolicy     #Not default, must install
 
Function Get-GPPUsers {
<#
.SYNOPSIS
    Uses GPOs to determine who is a privileged user for a specific GPO. Without any GUID assigned it will query the Default 
    Domain Controllers Policy.

    Author: Brandon Helms (@Cr0n1c)
    Version: 1.0

.SYNTAX
    Get-GPPUsers -Guid 6ac1786c-016f-11d2-945f-00c04fb984f9
    Get-GPPUsers -Name "Default Domain Controllers Policy"

#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,Position=1)]
        [string]$Guid = "6ac1786c-016f-11d2-945f-00c04fb984f9",

        [Parameter(Mandatory=$false)]
        [string]$Name
    )
    
    $privyUsers = @{} #key: users SamAccountName, value: array of privileges from $xmlCapPrivUser

    #Getting Policy Information
    try{
        if ($Name){
            [xml]$report = Get-GPOReport -Name $Name -ReportType Xml -ErrorAction Stop
        }else{
            [xml]$report = Get-GPOReport -Guid $Guid -ReportType Xml -ErrorAction Stop
        }
    }catch{
        Write-Error -Message "Best guess is that you tried to use a GPO that did not exist"
        exit
    }
    
    $linksApplied = $report.GPO.LinksTo.SomPath  #This will show all the OUs where the GPO has been applied"
    $xmlCapPrivUser = @("SeAssignPrimaryTokenPrivilege","SeCreateTokenPrivilege","SeCreateGlobalPrivilege","SeDebugPrivilege",
                        "SeEnableDelegationPrivilege","SeImpersonatePrivilege","SeInteractiveLogonRight","SeLoadDriverPrivilege",
                        "SeRemoteInteractiveLogonRight","SeRemoteShutdownPrivilege","SeRelabelPrivilege","SeSecurityPrivilege",
                        "SeSystemEnvironmentPrivilege","SeTakeOwnershipPrivilege","SeTrustedCredManAccessPrivilege",
                        "SeNetworkLogonRight","SeMachineAccountPrivilege")
     
    ForEach ($policy in $report.GPO.Computer.ExtensionData.Extension.UserRightsAssignment){
        If ($policy.Name -notin $xmlCapPrivUser){ #Ignoring keys we don't care about
            continue
        }
 
 
        ForEach ($uSid in $policy.Member.SID){ #Iterating through each SID
            If ($uSid.'#text'.length -gt 0){   #Making sure the SID is valid
                Convert-Sid $uSid.'#text' $policy.Name  #This function handles recursion
            }
        }
    }
    return $privyUsers
}
 
Function Convert-Sid($sid, $privLvl){
    $class = (Get-ADObject -Filter "objectSid -eq '$sid'").ObjectClass #pos: user, group, computer
 
 
    If ($class -eq "user"){
        $user = Get-ADUser -Filter {SID -eq $sid}
        $u = $user.SamAccountName
        $enabled = $user.Enabled
 
 
        If ($privyUsers.ContainsKey($u) -and -not $privyUsers.$u.Contains($privLvl)){
            $privyUsers.$u += $privLvl
        }ElseIf (-not $privyUsers.ContainsKey($u) -and $enabled){
            $privyUsers.Add($u, @($privLvl))
        }
 
 
    }ElseIf ($class -eq "group"){
        #If SID is a group,we'll pull out all the SIDs from the group and push them back through here
        $groupName = (Get-AdGroup -Filter {SID -eq $sid}).SamAccountName
 
 
        ForEach ($s in (Get-ADGroupMember -Identity $groupName).SID){
            Convert-Sid $s $privLvl
        }
    }
}
