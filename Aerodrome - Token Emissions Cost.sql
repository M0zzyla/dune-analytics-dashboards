WITH weekly_emissions AS (
    SELECT 
        DATE_TRUNC('week', evt_block_time) AS epoch_week,
        SUM(value / 1e18) AS aero_emitted_amount
    FROM erc20_base.evt_Transfer
    WHERE contract_address = from_hex('0x940181a94A35A4569E4529A3CDfB74e38FD98631') -- Скорректированный точный адрес токена AERO на Base
      AND "from" = from_hex('0x0000000000000000000000000000000000000000') -- Фильтруем чистый минт (создание токенов из пустоты)
      AND evt_block_time > NOW() - INTERVAL '180' DAY -- Берем последние 12 месяца
    GROUP BY 1
),
weekly_prices AS (
    SELECT 
        DATE_TRUNC('week', minute) AS epoch_week,
        AVG(price) AS avg_aero_price
    FROM prices.usd
    WHERE contract_address = from_hex('0x940181a94A35A4569E4529A3CDfB74e38FD98631') -- Цена AERO
      AND minute > NOW() - INTERVAL '180' DAY
    GROUP BY 1
)
SELECT 
    e.epoch_week,
    e.aero_emitted_amount,
    e.aero_emitted_amount * p.avg_aero_price AS emissions_value_usd
FROM weekly_emissions e
JOIN weekly_prices p ON e.epoch_week = p.epoch_week
ORDER BY 1 DESC;