USE BannerDb;
GO

-- 1. Pøíprava prostøedí
SET NOCOUNT ON;
ALTER DATABASE BannerDb SET RECOVERY BULK_LOGGED;
GO

-- Vypnutí omezení
BEGIN TRANSACTION;
EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
EXEC sp_msforeachtable 'ALTER TABLE ? DISABLE TRIGGER ALL';
COMMIT;
GO

-- 2. Tally table
DECLARE @RowsNeeded INT = 10000000;

IF OBJECT_ID('tempdb..#Tally') IS NOT NULL DROP TABLE #Tally;
CREATE TABLE #Tally (n INT PRIMARY KEY);

;WITH
L0 AS (SELECT 1 c UNION ALL SELECT 1),
L1 AS (SELECT 1 c FROM L0 a CROSS JOIN L0 b),
L2 AS (SELECT 1 c FROM L1 a CROSS JOIN L1 b),
L3 AS (SELECT 1 c FROM L2 a CROSS JOIN L2 b),
L4 AS (SELECT 1 c FROM L3 a CROSS JOIN L3 b)
INSERT INTO #Tally
SELECT TOP (@RowsNeeded) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) 
FROM L4;
GO

-- 3. Mapovací tabulky
CREATE TABLE #WebsiteMap (n INT, website_id INT);
CREATE TABLE #PriceListMap (n INT, price_list_id INT);
CREATE TABLE #BannerPositionMap (n INT, position_id INT);
CREATE TABLE #CampaignMap (n INT, campaign_id INT);
CREATE TABLE #BannerMap (position_id INT, banner_id INT);
GO

-- 4. Weby
INSERT INTO dbo.website (name, url)
OUTPUT inserted.id, inserted.id INTO #WebsiteMap
SELECT 
    'Web ' + CAST(n AS VARCHAR(10)),
    'https://web' + CAST(n AS VARCHAR(10)) + '.com'
FROM #Tally
WHERE n <= 30;
GO

-- 5. Cenové modely
INSERT INTO dbo.banner_pricing_model (id, name)
VALUES (1, 'CPC'), (2, 'CPM'), (3, 'CPA');
GO

-- 6. Ceníky
INSERT INTO dbo.banner_price_list (website_id, name, valid_from, valid_to)
OUTPUT inserted.id, inserted.id INTO #PriceListMap
SELECT 
    wm.website_id,
    'Price List ' + CAST(wm.n AS VARCHAR(10)),
    DATEADD(DAY, -30, GETDATE()),
    DATEADD(DAY, 30, GETDATE())
FROM #WebsiteMap wm;
GO

-- 7. Banner pozice
INSERT INTO dbo.banner_position (
    banner_pricing_model_id, 
    banner_price_list_id, 
    width, 
    height, 
    price, 
    currency
)
OUTPUT inserted.id, inserted.id INTO #BannerPositionMap
SELECT 
    pm.id,
    plm.price_list_id,
    sizes.width,
    sizes.height,
    sizes.base_price * pm.id,
    'CZK'
FROM #PriceListMap plm
CROSS JOIN dbo.banner_pricing_model pm
CROSS JOIN (VALUES 
    (300, 250, 5.0),
    (728, 90, 7.5),
    (160, 600, 8.0),
    (970, 250, 10.0)
) AS sizes(width, height, base_price);
GO

-- 8. Kampanì
INSERT INTO dbo.campaign (name, start_date, end_date)
OUTPUT inserted.id, inserted.id INTO #CampaignMap
SELECT 
    'Campaign ' + CAST(n AS VARCHAR(10)),
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 30, GETDATE()),
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 60, GETDATE())
FROM #Tally
WHERE n <= 300;
GO

-- 9. Propojení kampaní s pozicemi
INSERT INTO dbo.campaign_banner_position (campaign_id, banner_position_id)
SELECT 
    cm.campaign_id,
    bpm.position_id
FROM #CampaignMap cm
CROSS APPLY (
    SELECT TOP 3 position_id 
    FROM #BannerPositionMap 
    ORDER BY NEWID()
) bpm;
GO

-- 10. Bannery
CREATE TABLE #BannerCreation (position_id INT, banner_id INT);

MERGE INTO dbo.banner AS target
USING (
    SELECT 
        bpm.position_id,
        bp.width,
        bp.height
    FROM dbo.banner_position bp
    INNER JOIN #BannerPositionMap bpm 
        ON bp.id = bpm.position_id
) AS src (position_id, width, height)
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (width, height)
    VALUES (src.width, src.height)
OUTPUT src.position_id, inserted.id
INTO #BannerCreation (position_id, banner_id);

INSERT INTO #BannerMap (position_id, banner_id)
SELECT position_id, banner_id 
FROM #BannerCreation;
GO

-- 11. Banner placement
INSERT INTO dbo.banner_placement (banner_id, banner_position_id)
SELECT 
    bm.banner_id,
    bm.position_id
FROM #BannerMap bm;
GO

-- 12. Kliky - OPRAVA CHYBY (DATETIME2 místo DATE)
INSERT INTO dbo.banner_placement_click_event (banner_placement_id, event_timestamp)
SELECT 
    bp.id,
    DATEADD(
        SECOND, 
        ABS(CHECKSUM(NEWID())) % 
            CASE 
                WHEN DATEDIFF(SECOND, 
                    CAST(c.start_date AS DATETIME2), 
                    CAST(c.end_date AS DATETIME2)) > 0 
                THEN DATEDIFF(SECOND, 
                    CAST(c.start_date AS DATETIME2), 
                    CAST(c.end_date AS DATETIME2))
                ELSE 1
            END, 
        CAST(c.start_date AS DATETIME2)
    )
FROM dbo.banner_placement bp
JOIN dbo.campaign_banner_position cbp 
    ON bp.banner_position_id = cbp.banner_position_id
JOIN dbo.campaign c 
    ON c.id = cbp.campaign_id
CROSS APPLY (
    SELECT TOP (5000 + ABS(CHECKSUM(NEWID())) % 5001) 1 
    FROM #Tally
) r(n);
GO

-- 13. Objednávky - OPRAVA CHYBY (DATETIME2 místo DATE)
INSERT INTO dbo.[order] (banner_placement_id, order_date, price, margin)
SELECT
    bp.id,
    DATEADD(
        SECOND, 
        ABS(CHECKSUM(NEWID())) % 
            CASE 
                WHEN DATEDIFF(SECOND, 
                    CAST(c.start_date AS DATETIME2), 
                    CAST(c.end_date AS DATETIME2)) > 0 
                THEN DATEDIFF(SECOND, 
                    CAST(c.start_date AS DATETIME2), 
                    CAST(c.end_date AS DATETIME2))
                ELSE 1
            END, 
        CAST(c.start_date AS DATETIME2)
    ),
    500 + (500 * RAND(CHECKSUM(NEWID()))),
    100 + (200 * RAND(CHECKSUM(NEWID())))
FROM dbo.campaign_banner_position cbp
JOIN dbo.banner_placement bp 
    ON bp.banner_position_id = cbp.banner_position_id
JOIN dbo.campaign c 
    ON c.id = cbp.campaign_id
CROSS APPLY (
    SELECT TOP 1000 1 
    FROM #Tally
) r(n);
GO

-- 14. Obnova integrity
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Kontrola integrity
    DECLARE @BrokenFKs INT = 0;
    
    SELECT @BrokenFKs = COUNT(*)
    FROM dbo.banner_price_list bpl
    LEFT JOIN dbo.website w 
        ON bpl.website_id = w.id
    WHERE w.id IS NULL;
    
    IF @BrokenFKs > 0
    BEGIN
        RAISERROR('Nalezeny neplatné reference v banner_price_list!', 16, 1);
    END
    
    -- Obnova omezení
    DECLARE @sql NVARCHAR(MAX) = N'';
    SELECT @sql += N'ALTER TABLE ' + 
        QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.' + QUOTENAME(t.name) + 
        ' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(fk.name) + ';' + CHAR(13)
    FROM sys.foreign_keys fk
    JOIN sys.tables t 
        ON fk.parent_object_id = t.object_id;
    
    EXEC sp_executesql @sql;
    
    -- Zapnutí triggerù
    EXEC sp_msforeachtable 'ALTER TABLE ? ENABLE TRIGGER ALL';
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH

-- 15. Úklid
ALTER DATABASE BannerDb SET RECOVERY FULL;
DROP TABLE IF EXISTS #Tally;
DROP TABLE IF EXISTS #WebsiteMap;
DROP TABLE IF EXISTS #PriceListMap;
DROP TABLE IF EXISTS #BannerPositionMap;
DROP TABLE IF EXISTS #CampaignMap;
DROP TABLE IF EXISTS #BannerMap;
DROP TABLE IF EXISTS #BannerCreation;
GO

PRINT 'Skript úspìšnì dokonèen!';
