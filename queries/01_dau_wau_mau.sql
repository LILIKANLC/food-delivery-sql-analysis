/* Metrics: DAU / WAU / MAU
Description: Unique users who performed at least one action per day, week, and month.
Shows overall audience activity dynamics.
Tables used: user_actions */

-- Daily Active Users (DAU)
SELECT
    time::date AS date,
    COUNT(DISTINCT user_id) AS dau
FROM user_actions
GROUP BY date
ORDER BY date;

-- Weekly Active Users (WAU)
SELECT
    DATE_TRUNC('week', time)::date AS week,
    COUNT(DISTINCT user_id) AS wau
FROM user_actions
GROUP BY week
ORDER BY week;

-- Monthly Active Users (MAU)
SELECT
    DATE_TRUNC('month', time)::date AS month,
    COUNT(DISTINCT user_id) AS mau
FROM user_actions
GROUP BY month
ORDER BY month;
