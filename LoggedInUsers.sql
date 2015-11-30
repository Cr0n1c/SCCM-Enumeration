SELECT       
     v_R_System.Name0,
     v_GS_COMPUTER_SYSTEM.Model0,     
     v_GS_COMPUTER_SYSTEM.Manufacturer0,  
     v_R_System.AD_Site_Name0,  
     v_R_User.Full_User_Name0,
     v_GS_SYSTEM_CONSOLE_USER.SystemConsoleUser0,  
     v_GS_SYSTEM_CONSOLE_USER.LastConsoleUse0,  
     v_GS_SYSTEM_CONSOLE_USER.TimeStamp,
     v_GS_SYSTEM_CONSOLE_USER.TotalUserConsoleMinutes0
FROM             
     v_R_System
JOIN 
     v_GS_SYSTEM_CONSOLE_USER ON v_R_System.ResourceID = v_GS_SYSTEM_CONSOLE_USER.ResourceID 
JOIN
     v_R_User ON v_GS_SYSTEM_CONSOLE_USER.SystemConsoleUser0 = v_R_User.Unique_User_Name0
JOIN
     v_GS_COMPUTER_SYSTEM ON v_R_System.ResourceID = v_GS_COMPUTER_SYSTEM.ResourceID
