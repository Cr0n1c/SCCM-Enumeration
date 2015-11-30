SELECT DISTINCT
   UD.User_Name0
   ,UD.Full_Domain_Name0
   ,UD.Distinguished_Name0
   ,CM.Name
   ,CM.Domain
   ,CM.SiteCode
FROM
    v_UsersPrimaryMachines PM
JOIN
    CollectionMembers CM ON CM.MachineID = PM.MachineID
JOIN
    User_DISC UD ON UD.ItemKey = PM.UserResourceID
