-- Kontrola èasových razítek
SELECT TOP 10
    event_timestamp,
    DATEDIFF(SECOND, start_date, event_timestamp) AS DiffSeconds
FROM dbo.banner_placement_click_event bce
JOIN dbo.banner_placement bp ON bce.banner_placement_id = bp.id
JOIN dbo.campaign_banner_position cbp ON bp.banner_position_id = cbp.banner_position_id
JOIN dbo.campaign c ON cbp.campaign_id = c.id;

-- Statistiky
SELECT 
    (SELECT COUNT(*) FROM dbo.website) AS Websites,
    (SELECT COUNT(*) FROM dbo.campaign) AS Campaigns,
    (SELECT COUNT(*) FROM dbo.banner_placement) AS BannerPlacements,
    (SELECT COUNT(*) FROM dbo.banner_placement_click_event) AS Clicks,
    (SELECT COUNT(*) FROM dbo.[order]) AS Orders;