-- 1. Vista de países con alto PIB per cápita
CREATE OR REPLACE VIEW vw_paises_alto_pib_per_capita AS
SELECT
    c.code,
    c.name,
    c.area,
    c.population,
    e.gdp,
    (e.gdp / NULLIF(c.population, 0)) AS pib_per_capita
FROM Country c
JOIN Economy e ON e.country = c.code
WHERE (e.gdp / NULLIF(c.population, 0)) > 30000; -- se puede ajustar dependiendo uno que considere que es ya estar billetudo

-- 2. Vista de ciudades costeras (No se que tan fan soy de vivir en la costa,no soy fan de los mariscos igual, viva Cali y su diversidad)
CREATE OR REPLACE VIEW vw_ciudades_costeras AS
SELECT DISTINCT
    ci.name,
    ci.country,
    ci.province,
    ci.population,
    ci.latitude,
    ci.longitude,
    l.sea
FROM City ci
JOIN located l
  ON l.city = ci.name AND l.country = ci.country AND l.province = ci.province
WHERE l.sea IS NOT NULL;

-- 3. Vista de países con múltiples continentes
CREATE OR REPLACE VIEW vw_paises_multicontinente AS
SELECT
    e.country,
    c.name,
    COUNT(DISTINCT e.continent) AS continentes
FROM encompasses e
JOIN Country c ON c.code = e.country
GROUP BY e.country, c.name
HAVING COUNT(DISTINCT e.continent) > 1;

-- 4. Función: calcular crecimiento poblacional anual (CAGR) entre dos años usando Countrypops
CREATE OR REPLACE FUNCTION fn_crecimiento_poblacional_anual(
    p_country  VARCHAR(4),
    p_year_ini DECIMAL,
    p_year_fin DECIMAL
) RETURNS NUMERIC AS $$
DECLARE
    v_p0 DECIMAL;
    v_p1 DECIMAL;
    v_years DECIMAL;
BEGIN
    IF p_year_fin <= p_year_ini THEN
        RETURN NULL;
    END IF;

    SELECT population INTO v_p0
    FROM Countrypops
    WHERE country = p_country AND year = p_year_ini;

    SELECT population INTO v_p1
    FROM Countrypops
    WHERE country = p_country AND year = p_year_fin;

    IF v_p0 IS NULL OR v_p1 IS NULL OR v_p0 = 0 THEN
        RETURN NULL;
    END IF;

    v_years := p_year_fin - p_year_ini;
    RETURN POWER(v_p1 / v_p0, 1 / v_years) - 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- 5. Función: distancia aproximada entre dos ciudades (Haversine en km)
CREATE OR REPLACE FUNCTION fn_distancia_ciudades_km(
    p_city1 VARCHAR(50), p_country1 VARCHAR(4), p_prov1 VARCHAR(50),
    p_city2 VARCHAR(50), p_country2 VARCHAR(4), p_prov2 VARCHAR(50)
) RETURNS NUMERIC AS $$
DECLARE
    r_km CONSTANT NUMERIC := 6371;
    lat1 NUMERIC; lon1 NUMERIC;
    lat2 NUMERIC; lon2 NUMERIC;
    dlat NUMERIC; dlon NUMERIC;
BEGIN
    SELECT latitude, longitude INTO lat1, lon1
    FROM City
    WHERE name = p_city1 AND country = p_country1 AND province = p_prov1;

    SELECT latitude, longitude INTO lat2, lon2
    FROM City
    WHERE name = p_city2 AND country = p_country2 AND province = p_prov2;

    IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
        RETURN NULL;
    END IF;

    dlat := RADIANS(lat2 - lat1);
    dlon := RADIANS(lon2 - lon1);

    RETURN r_km * 2 * ASIN(
        SQRT(
            POWER(SIN(dlat / 2), 2) +
            COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * POWER(SIN(dlon / 2), 2)
        )
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- 6. Procedimiento: insertar una ciudad con validación
CREATE OR REPLACE PROCEDURE sp_insertar_ciudad(
    p_name       VARCHAR(50),
    p_country    VARCHAR(4),
    p_province   VARCHAR(50),
    p_population DECIMAL,
    p_latitude   DECIMAL,
    p_longitude  DECIMAL,
    p_elevation  DECIMAL DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_country_exists VARCHAR(4);
    v_province_exists VARCHAR(4);
BEGIN
    SELECT code INTO v_country_exists FROM Country WHERE code = p_country;
    IF v_country_exists IS NULL THEN
        RETURN;
    END IF;

    SELECT country INTO v_province_exists
    FROM Province
    WHERE name = p_province AND country = p_country;
    IF v_province_exists IS NULL THEN
        RETURN;
    END IF;

    IF p_population < 0 OR p_latitude NOT BETWEEN -90 AND 90 OR p_longitude NOT BETWEEN -180 AND 180 THEN
        RETURN;
    END IF;

    INSERT INTO City(name, country, province, population, latitude, longitude, elevation)
    VALUES (p_name, p_country, p_province, p_population, p_latitude, p_longitude, p_elevation);
END;
$$;

-- 7. Trigger: prevenir población negativa en City (ajusta a 0 automáticamente)
CREATE OR REPLACE FUNCTION trg_no_poblacion_negativa_fn()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.population < 0 THEN
        NEW.population := 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_no_poblacion_negativa ON City;
CREATE TRIGGER trg_no_poblacion_negativa
BEFORE INSERT OR UPDATE ON City
FOR EACH ROW
EXECUTE FUNCTION trg_no_poblacion_negativa_fn();