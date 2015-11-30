SELECT       
     RS.Name0,   
     GS.SystemConsoleUser0,  
     GS.LastConsoleUse0
FROM             
     v_R_System RS
JOIN 
     v_GS_SYSTEM_CONSOLE_USER GS ON RS.ResourceID = GS.ResourceID
