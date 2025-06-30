WITH ClickCounts AS (
    SELECT
        cbp.campaign_id,
        cbp.banner_position_id,
        COUNT(*) AS click_count
    FROM dbo.banner_placement_click_event ce
    INNER JOIN dbo.banner_placement bp ON ce.banner_placement_id = bp.id
    INNER JOIN dbo.banner_position bpos ON bp.banner_position_id = bpos.id
    INNER JOIN dbo.campaign_banner_position cbp ON cbp.banner_position_id = bpos.id
    GROUP BY cbp.campaign_id, cbp.banner_position_id
),
Margins AS (
    SELECT
        c.id AS campaign_id,
        SUM(o.margin) AS total_margin
    FROM dbo.campaign c
    INNER JOIN dbo.campaign_banner_position cbp ON cbp.campaign_id = c.id
    INNER JOIN dbo.banner_position bp ON bp.id = cbp.banner_position_id
    INNER JOIN dbo.banner_pricing_model bpm ON bpm.id = bp.banner_pricing_model_id
    INNER JOIN dbo.banner_placement bpl ON bpl.banner_position_id = bp.id
    INNER JOIN dbo.[order] o ON o.banner_placement_id = bpl.id
    GROUP BY c.id
),
Costs AS (
    SELECT
        c.id AS campaign_id,
        SUM(
            CASE
                WHEN bpm.id = 2 THEN (DATEDIFF(DAY, c.start_date, c.end_date) + 1) * ISNULL(bp.price,0)
                WHEN bpm.id = 1 THEN ISNULL(cc.click_count,0) * ISNULL(bp.price,0)
                ELSE 0
            END
        ) AS total_costs
    FROM dbo.campaign c
    INNER JOIN dbo.campaign_banner_position cbp ON cbp.campaign_id = c.id
    INNER JOIN dbo.banner_position bp ON bp.id = cbp.banner_position_id
    INNER JOIN dbo.banner_pricing_model bpm ON bpm.id = bp.banner_pricing_model_id
    LEFT JOIN ClickCounts cc
        ON cc.campaign_id = c.id
       AND cc.banner_position_id = bp.id
    GROUP BY c.id, c.start_date, c.end_date
)
SELECT
    c.id AS campaign_id,
    c.name AS campaign_name,
    ISNULL(m.total_margin,0) AS total_margin,
    ISNULL(cs.total_costs,0) AS total_costs,
    ISNULL(m.total_margin,0) - ISNULL(cs.total_costs,0) AS balance
FROM dbo.campaign c
LEFT JOIN Margins m ON m.campaign_id = c.id
LEFT JOIN Costs cs ON cs.campaign_id = c.id
ORDER BY balance DESC;