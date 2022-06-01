WITH sale AS (
    SELECT
        f2,
        f3,
        f4,
        round(AVG(p_m)) AS ppsm
    FROM
        (
            SELECT
                f1,
                f2,
                regexp_substr(f3, '^.*?\s')                                                                                                      AS f3,
                f4,
                CAST(replace(regexp_substr(f5, '^[^/]*'), '.', ',') AS FLOAT)                                                                    AS f5,
                f6,
                CAST(replace(f7, ' ', '') AS INT)                                                                                                AS f7,
                round(CAST(replace(f7, ' ', '') AS INT) / CAST(replace(regexp_substr(f5, '^[^/]*'), '.', ',') AS FLOAT))                         p_m
            FROM
                student00.realty_sale_data t1
        ) a
    GROUP BY
        f2,
        f3,
        f4
), rent AS (
    SELECT DISTINCT
        f2,
        f3,
        f4,
        round(f7 / f5) * 12 AS rent_m_year
    FROM
        (
            SELECT
                f2,
                f3,
                f4,
                CASE
                    WHEN f5 IS NULL
                         AND avg_s IS NULL THEN
                        avg_s_u
                    WHEN f5 IS NULL THEN
                        avg_s_u
                    ELSE
                        f5
                END f5,
                f7
            FROM
                (
                    SELECT
                        t1.*,
                        t2.avg_s,
                        t3.avg_s_u
                    FROM
                        (
                            SELECT
                                f2,
                                nvl(regexp_substr(f3, '^.*?\s'), 'нет')                                                                       AS f3,
                                f4,
                                round(CAST(replace(replace(regexp_substr(f5, '^[^/]*'), '-', NULL), '.', ',') AS FLOAT))                      AS f5,
                                CAST(replace(f7, ' ', '') AS INT)                                                                             AS f7
                            FROM
                                student00.realty_rent_data
                        )  t1
                        LEFT JOIN (
                            SELECT
                                f2,
                                f3,
                                f4,
                                round(AVG(f5)) AS avg_s
                            FROM
                                (
                                    SELECT
                                        f1,
                                        f2,
                                        nvl(regexp_substr(f3, '^.*?\s'), 'нет')                                                             AS f3,
                                        f4,
                                        CAST(replace(replace(regexp_substr(f5, '^[^/]*'), '-', NULL), '.', ',') AS FLOAT)                   AS f5,
                                        CAST(replace(f7, ' ', '') AS INT)                                                                   AS f7
                                    FROM
                                        student00.realty_rent_data
                                )
                            GROUP BY
                                f2,
                                f3,
                                f4
                        )  t2 ON t1.f2 = t2.f2
                                AND t1.f3 = t2.f3
                                AND t1.f4 = t2.f4
                        LEFT JOIN (
                            SELECT
                                f4,
                                round(AVG(f5)) AS avg_s_u
                            FROM
                                (
                                    SELECT
                                        f1,
                                        f2,
                                        nvl(regexp_substr(f3, '^.*?\s'), 'нет')                                                             AS f3,
                                        f4,
                                        CAST(replace(replace(regexp_substr(f5, '^[^/]*'), '-', NULL), '.', ',') AS FLOAT)                   AS f5,
                                        CAST(replace(f7, ' ', '') AS INT)                                                                   AS f7
                                    FROM
                                        student00.realty_rent_data
                                )
                            GROUP BY
                                f4
                        )  t3 ON t1.f4 = t3.f4
                )
        )
)




select f4, round(avg(rental_rate),6)
from(SELECT
    t1.*,
    t2.rent_m_year,
    round(t2.rent_m_year / t1.ppsm *100, 2) as rental_rate
FROM
         sale t1
    JOIN rent t2 ON t1.f2 = t2.f2
                    AND t1.f3 = t2.f3
                    AND t1.f4 = t2.f4
order by round(t2.rent_m_year / t1.ppsm *100, 2) desc)
group by f4
order by f4 asc



