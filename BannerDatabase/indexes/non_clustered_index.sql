USE BannerDB;

CREATE NONCLUSTERED INDEX ix_bpce_placement_date
ON dbo.banner_placement_click_event(banner_placement_id, event_timestamp);

CREATE NONCLUSTERED INDEX IX_banner_placement_banner_position_id
    ON dbo.banner_placement (banner_position_id);

CREATE NONCLUSTERED INDEX IX_campaign_banner_position_banner_position_id
    ON dbo.campaign_banner_position (banner_position_id, campaign_id );

CREATE NONCLUSTERED INDEX IX_banner_position_pricing_model
ON dbo.banner_position (banner_pricing_model_id, id);


-- Objednávky s datem
--CREATE NONCLUSTERED INDEX IX_order_date_banner
--ON dbo.[order] (order_date, banner_placement_id);

