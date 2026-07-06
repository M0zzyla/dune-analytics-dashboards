WITH revenue_data AS (
    SELECT 
        DATE_TRUNC('week', block_time) AS epoch_week,
        SUM(amount_usd) * 0.0008 AS estimated_fees_usd 
    FROM dex.trades
    WHERE blockchain = 'base'
      AND project = 'aerodrome'
      AND block_time > NOW() - INTERVAL '180' DAY
    GROUP BY 1
),
emissions_data AS (
    SELECT 
        DATE_TRUNC('week', evt_block_time) AS epoch_week,
        SUM(value / 1e18) AS aero_emitted_amount
    FROM erc20_base.evt_Transfer
    WHERE contract_address = from_hex('0x940181a94A35A4569E4529A3CDfB74e38FD98631')
      AND "from" = from_hex('0x0000000000000000000000000000000000000000')
      AND evt_block_time > NOW() - INTERVAL '180' DAY
    GROUP BY 1
),
weekly_prices AS (
    SELECT 
        DATE_TRUNC('week', minute) AS epoch_week,
        AVG(price) AS avg_aero_price
    FROM prices.usd
    WHERE contract_address = from_hex('0x940181a94A35A4569E4529A3CDfB74e38FD98631')
      AND minute > NOW() - INTERVAL '180' DAY
    GROUP BY 1
),
calculated_emissions AS (
    SELECT 
        e.epoch_week,
        e.aero_emitted_amount * p.avg_aero_price AS emissions_value_usd
    FROM emissions_data e
    JOIN weekly_prices p ON e.epoch_week = p.epoch_week
)
SELECT 
    r.epoch_week,
    r.estimated_fees_usd AS protocol_revenue_usd,
    c.emissions_value_usd AS emission_cost_usd,
    (r.estimated_fees_usd - c.emissions_value_usd) AS net_profit_usd,
    (r.estimated_fees_usd / c.emissions_value_usd) AS efficiency_ratio,
    1.0 AS baseline_efficiency
FROM revenue_data r
JOIN calculated_emissions c ON r.epoch_week = c.epoch_week
ORDER BY 1 DESC;
