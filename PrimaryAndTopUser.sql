SELECT DISTINCT
    GS.TopConsoleUser0 [TopUser],
    UD.User_Name0 [PrimaryUser],
    CM.Name [Computer],
    IP.IPAddress0 [IP],
    IP.DefaultIPGateway0 [GW]
FROM
    v_GS_SYSTEM_CONSOLE_USAGE_MAXGROUP GS
LEFT JOIN
    CollectionMembers CM ON GS.ResourceID = CM.MachineID
LEFT JOIN
    v_UsersPrimaryMachines PM ON GS.ResourceID = PM.MachineID
LEFT JOIN
    User_DISC UD ON UD.ItemKey = PM.UserResourceID
LEFT JOIN
     v_GS_NETWORK_ADAPTER_CONFIGUR IP ON GS.ResourceID = IP.ResourceID
WHERE
    IP.IPAddress0 is not null
AND
    IP.DefaultIPGateway0  != '0.0.0.0'
AND
    GS.TopConsoleUser0 like '$domain%'  --Replace $domain with the network domain
AND
    IP.DefaultIPGateway0 not like ':'
