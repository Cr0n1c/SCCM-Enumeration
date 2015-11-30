SELECT DISTINCT
    CM.Name,
    GS.TopConsoleUser0,
    GS.SecurityLogStartDate0,
    GS.TotalConsoleTime0,
    GS.TotalConsoleUsers0,
    GS.TotalSecurityLogTime0
FROM
    v_GS_SYSTEM_CONSOLE_USAGE_MAXGROUP GS
JOIN
    CollectionMembers CM ON GS.ResourceID = CM.MachineID
ORDER BY
    TotalConsoleTime0 DESC
