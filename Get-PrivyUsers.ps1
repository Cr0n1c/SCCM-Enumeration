Import-Module activedirectory #Not default, must install
Import-Module grouppolicy     #Not default, must install
 
 
#NOTE: Will not run on PowerShell v2
$global:privyUsers = @{} #key: users SamAccountName, value: array of privileges from $xmlCapPrivUser
 
 
Function Get-PrivyUsers {
    #Getting "Default Domain Controller Policy"
    [xml]$report = Get-GPOReport -Guid 6ac1786c-016f-11d2-945f-00c04fb984f9 -ReportType Xml -ErrorAction Stop
    $global:linksApplied = $report.GPO.LinksTo.SomPath  #This will show all the OUs where the GPO has been applied"
    $xmlCapPrivUser = @("SeAssignPrimaryTokenPrivilege","SeAuditPrivilege","SeBackupPrivilege","SeBatchLogonRight",
                        "SeCreatePagefilePrivilege","SeCreatePermanentPrivilege","SeCreateTokenPrivilege",
                        "SeDebugPrivilege","SeEnableDelegationPrivilege","SeIncreaseBasePriorityPrivilege",
                        "SeIncreaseQuotaPrivilege","SeInteractiveLogonRight","SeLoadDriverPrivilege",
                        "SeLockMemoryPrivilege","SeProfileSingleProcessPrivilege","SeRemoteShutdownPrivilege",
                        "SeRestorePrivilege","SeSecurityPrivilege","SeServiceLogonRight","SeShutdownPrivilege",
                        "SeTakeOwnershipPrivilege","SeTcbPrivilege","SeUndockPrivilege","SeSyncAgentPrivilege",
                        "SeSystemEnvironmentPrivilege","SeSystemProfilePrivilege","SeSystemTimePrivilege")
     
    ForEach ($policy in $report.GPO.Computer.ExtensionData.Extension.UserRightsAssignment){
        If ($policy.Name -notin $xmlCapPrivUser){ #Ignoring key we don't care about
            continue
        }
 
 
        ForEach ($uSid in $policy.Member.SID){ #Iterating through each SID
            If ($uSid.'#text'.length -gt 0){   #Making sure the SID is valid
                Convert-Sid $uSid.'#text' $policy.Name  #This function handles recursion
            }
        }
    }
}
 
Function Convert-Sid($sid, $privLvl){
    $class = (Get-ADObject -Filter "objectSid -eq '$sid'").ObjectClass #pos: user, group, computer
 
 
    If ($class -eq "user"){
        $user = Get-ADUser -Filter {SID -eq $sid}
        $u = $user.SamAccountName
        $enabled = $user.Enabled
 
 
        If ($global:privyUsers.ContainsKey($u) -and -not $global:privyUsers.$u.Contains($privLvl)){
            $global:privyUsers.$u += $privLvl
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
 
Get-PrivyUsers
 
#All data that you care about will be stored in $global:privyUsers
