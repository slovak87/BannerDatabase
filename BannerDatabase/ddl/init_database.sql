USE BannerDb;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'campaign'
)
BEGIN
    CREATE TABLE dbo.campaign (
        id         INT IDENTITY(1,1) NOT NULL,
        name       NVARCHAR(255)      NOT NULL,
        start_date DATE               NULL,
        end_date   DATE               NULL,
        CONSTRAINT pk_campaign PRIMARY KEY (id),
        CONSTRAINT chk_campaign_dates 
            CHECK (start_date IS NULL OR end_date IS NULL OR start_date < end_date)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'banner_pricing_model'
)
BEGIN
    CREATE TABLE dbo.banner_pricing_model (
        id   TINYINT  NOT NULL,
        name NVARCHAR(255) NOT NULL,
        CONSTRAINT pk_banner_pricing_model PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'website'
)
BEGIN
    CREATE TABLE dbo.website (
        id   INT IDENTITY(1,1) NOT NULL,
        name NVARCHAR(255)      NOT NULL,
        url  NVARCHAR(2083)     NULL,
        CONSTRAINT pk_website PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'banner_price_list'
)
BEGIN
    CREATE TABLE dbo.banner_price_list (
        id            INT IDENTITY(1,1) NOT NULL,
        website_id    INT               NOT NULL,
        name          NVARCHAR(255)     NOT NULL,
        valid_from    DATE              NOT NULL,  -- Povinné pole
        valid_to      DATE              NULL,
        CONSTRAINT pk_banner_price_list PRIMARY KEY (id),
        CONSTRAINT fk_banner_price_list_website
            FOREIGN KEY (website_id)
            REFERENCES dbo.website (id),
        CONSTRAINT chk_valid_dates 
            CHECK (valid_to IS NULL OR valid_from < valid_to)  -- Kontrola datumù
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'banner_position'
)
BEGIN
    CREATE TABLE dbo.banner_position (
        id                      INT IDENTITY(1,1) NOT NULL,
        banner_pricing_model_id TINYINT           NOT NULL,
        banner_price_list_id    INT               NOT NULL,
        width                   INT               NULL,
        height                  INT               NULL,
        price                   DECIMAL(18,2)     NULL,
        currency                CHAR(3)           NULL,
        CONSTRAINT pk_banner_position PRIMARY KEY (id),
        CONSTRAINT fk_banner_position_pricing_model
            FOREIGN KEY (banner_pricing_model_id)
            REFERENCES dbo.banner_pricing_model (id),
        CONSTRAINT fk_banner_position_price_list
            FOREIGN KEY (banner_price_list_id)
            REFERENCES dbo.banner_price_list (id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'campaign_banner_position'
)
BEGIN
    CREATE TABLE dbo.campaign_banner_position (
        id                INT IDENTITY(1,1) NOT NULL,
        campaign_id       INT NOT NULL,
        banner_position_id INT NOT NULL,
        CONSTRAINT pk_campaign_banner_position PRIMARY KEY (id),
        CONSTRAINT fk_cbp_campaign
            FOREIGN KEY (campaign_id)
            REFERENCES dbo.campaign (id),
        CONSTRAINT fk_cbp_banner_position
            FOREIGN KEY (banner_position_id)
            REFERENCES dbo.banner_position (id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'banner'
)
BEGIN
    CREATE TABLE dbo.banner (
        id     INT IDENTITY(1,1) NOT NULL,
        width  INT               NULL,
        height INT               NULL,
        CONSTRAINT pk_banner PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'banner_placement'
)
BEGIN
    CREATE TABLE dbo.banner_placement (
        id                 INT IDENTITY(1,1) NOT NULL,
        banner_id          INT NOT NULL,
        banner_position_id INT NOT NULL,
        CONSTRAINT pk_banner_placement PRIMARY KEY (id),
        CONSTRAINT fk_bp_banner
            FOREIGN KEY (banner_id)
            REFERENCES dbo.banner (id),
        CONSTRAINT fk_bp_banner_position
            FOREIGN KEY (banner_position_id)
            REFERENCES dbo.banner_position (id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'banner_placement_click_event'
)
BEGIN
    CREATE TABLE dbo.banner_placement_click_event (
        id                  INT IDENTITY(1,1) NOT NULL,
        banner_placement_id INT              NOT NULL,
        event_timestamp     DATETIME2        NOT NULL,
        valid_to            DATETIME2        NULL,
        CONSTRAINT pk_banner_placement_click_event PRIMARY KEY (id),
        CONSTRAINT fk_bpce_banner_placement
            FOREIGN KEY (banner_placement_id)
            REFERENCES dbo.banner_placement (id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = N'[order]'
)
BEGIN
    CREATE TABLE dbo.[order] (
        id                  INT IDENTITY(1,1) NOT NULL,
        banner_placement_id INT              NOT NULL,
        order_date          DATETIME2        NOT NULL,
        price               DECIMAL(18,2)    NULL,
        margin              DECIMAL(18,2)    NULL,
        CONSTRAINT pk_order PRIMARY KEY (id),
        CONSTRAINT fk_order_banner_placement
            FOREIGN KEY (banner_placement_id)
            REFERENCES dbo.banner_placement (id)
    );
END
GO