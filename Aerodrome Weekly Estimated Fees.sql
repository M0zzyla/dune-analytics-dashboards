SELECT 
    DATE_TRUNC('week', block_time) AS epoch_week,
    SUM(amount_usd) AS total_volume_usd,
    -- Для базовой оценки берем среднюю комиссию ~0.08%
    SUM(amount_usd) * 0.0008 AS estimated_fees_usd 
FROM dex.trades
WHERE blockchain = 'base'
  AND project = 'aerodrome'
  AND block_time > NOW() - INTERVAL '180' DAY -- берем последние полгода
GROUP BY 1
ORDER BY 1 DESC;