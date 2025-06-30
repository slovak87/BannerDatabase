WITH daily_costs AS (
    SELECT
        DATEPART(WEEKDAY, day_date) AS weekday_number,
        SUM(bp.price) AS total_cost
    FROM dbo.campaign c
    JOIN dbo.campaign_banner_position cbp
        ON cbp.campaign_id = c.id
    JOIN dbo.banner_position bp
        ON bp.id = cbp.banner_position_id
       AND bp.banner_pricing_model_id = 2
    CROSS APPLY (
        SELECT DATEADD(DAY, v.number, c.start_date) AS day_date
        FROM master..spt_values v
        WHERE v.type = 'P'
          AND v.number <= DATEDIFF(DAY, c.start_date, c.end_date)
    ) AS days
    GROUP BY DATEPART(WEEKDAY, day_date)
),
daily_revenues AS (
    SELECT
        DATEPART(WEEKDAY, o.order_date) AS weekday_number,
        SUM(o.margin) AS total_revenue
    FROM dbo.[order] o
    JOIN dbo.banner_placement bpmt
        ON bpmt.id = o.banner_placement_id
    JOIN dbo.banner_position bp
        ON bp.id = bpmt.banner_position_id
       AND bp.banner_pricing_model_id = 2
    GROUP BY DATEPART(WEEKDAY, o.order_date)
)
SELECT
    d.n AS weekday_number,
    DATENAME(WEEKDAY, DATEADD(DAY, d.n - 1, '20230101')) AS weekday_name,
    ISNULL(dr.total_revenue,0) AS total_revenue,
    ISNULL(dc.total_cost,0) AS total_cost,
    ISNULL(dr.total_revenue,0) - ISNULL(dc.total_cost,0) AS balance
FROM (VALUES (1),(2),(3),(4),(5),(6),(7)) AS d(n) -- 1=Sunday, 2=Monday, etc. (default SQL Server setting)
LEFT JOIN daily_costs dc
    ON dc.weekday_number = d.n
LEFT JOIN daily_revenues dr
    ON dr.weekday_number = d.n
ORDER BY
    CASE d.n
        WHEN 2 THEN 1 -- Monday
        WHEN 3 THEN 2 -- Tuesday
        WHEN 4 THEN 3 -- Wednesday
        WHEN 5 THEN 4 -- Thursday
        WHEN 6 THEN 5 -- Friday
        WHEN 7 THEN 6 -- Saturday
        WHEN 1 THEN 7 -- Sunday
    END;