-- 1. Países que NO tienen litoral (sin mares asociados en geo_Sea)
SELECT c.code, c.name
FROM Country c
WHERE NOT EXISTS (
    SELECT 1
    FROM geo_Sea gs
    WHERE gs.country = c.code
);

-- 2. Ríos que pasan por más de un país
SELECT
    gr.river,
    COUNT(DISTINCT gr.country) AS num_paises
FROM geo_River gr
GROUP BY gr.river
HAVING COUNT(DISTINCT gr.country) > 1;

-- 3. Continentes con mayor densidad poblacional
-- Se prorratea población y área por porcentaje en encompasses.
WITH contrib AS (
    SELECT
        e.continent,
        (c.population * (e.percentage / 100)) AS poblacion_parcial,
        (c.area * (e.percentage / 100))       AS area_parcial
    FROM encompasses e
    JOIN Country c ON c.code = e.country
),
agg AS (
    SELECT
        continent,
        SUM(poblacion_parcial) AS poblacion,
        SUM(area_parcial)      AS area
    FROM contrib
    GROUP BY continent
)
SELECT
    continent,
    poblacion,
    area,
    (poblacion / NULLIF(area, 0)) AS densidad
FROM agg
ORDER BY densidad DESC NULLS LAST;