SELECT
    u.[Computer Name],
    u.[Product Name],
    u.Publisher,
    u.Version,
    u.InstallDate0
FROM (
    SELECT DISTINCT
        v_R_System_Valid.Netbios_Name0 AS 'Computer Name',
        v_R_System_Valid.ResourceID,
        v_GS_ADD_REMOVE_PROGRAMS_64.DisplayName0 AS 'Product Name',
        v_GS_ADD_REMOVE_PROGRAMS_64.Publisher0 AS 'Publisher',
        v_GS_ADD_REMOVE_PROGRAMS_64.Version0 AS 'Version',
        v_GS_ADD_REMOVE_PROGRAMS_64.InstallDate0
    FROM
        v_GS_ADD_REMOVE_PROGRAMS_64
    INNER JOIN
        v_R_System_Valid ON v_R_System_Valid.ResourceID = v_GS_ADD_REMOVE_PROGRAMS_64.ResourceID
    JOIN
        v_GS_OPERATING_SYSTEM ON v_GS_ADD_REMOVE_PROGRAMS_64.ResourceID = v_GS_OPERATING_SYSTEM.ResourceID
    UNION ALL
    (
        SELECT DISTINCT
            v_R_System_Valid.Netbios_Name0 AS 'Computer Name',
            v_R_System_Valid.ResourceID,
            [dbo].[v_GS_ADD_REMOVE_PROGRAMS].[DisplayName0] AS 'Product Name',
            [dbo].[v_GS_ADD_REMOVE_PROGRAMS].[Publisher0] AS 'Publisher',
            [dbo].[v_GS_ADD_REMOVE_PROGRAMS].[Version0] AS 'Version',
            [dbo].[v_GS_ADD_REMOVE_PROGRAMS].[InstallDate0]
        FROM
            [dbo].[v_GS_ADD_REMOVE_PROGRAMS]
        INNER JOIN
            v_R_System_Valid ON v_R_System_Valid.ResourceID = v_GS_ADD_REMOVE_PROGRAMS.ResourceID
        JOIN
            v_GS_OPERATING_SYSTEM ON v_GS_ADD_REMOVE_PROGRAMS.ResourceID = v_GS_OPERATING_SYSTEM.ResourceID
    )
) AS u
ORDER BY
    'Computer Name',
    'Product Name',
    Publisher,
    Version
