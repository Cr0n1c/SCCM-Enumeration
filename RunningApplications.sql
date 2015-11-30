SELECT GS.Name0,
     VEX.TimeStamp,
     VEX.FolderPath0,
     VEX.ExplorerFileName0,
     VEX.LastUserName0,
     VEX.OriginalFileName0,
     VEX.FileVersion0,
     VEX.FileSize0,
     VEX.ProductName0,
     VEX.ProductVersion0,
     VEX.ProductLanguage0,
     VEX.FileDescription0,
     VEX.CompanyName0,
     VEX.LastUsedTime0,
     VEX.ProductCode0,
     VEX.msiDisplayName0,
     VEX.msiPublisher0
FROM SCCM_Ext.vex_GS_CCM_RECENTLY_USED_APPS VEX
JOIN V_GS_SYSTEM GS ON GS.ResourceID = VEX.ResourceID
