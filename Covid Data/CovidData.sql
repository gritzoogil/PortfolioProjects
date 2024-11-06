SELECT *
FROM ProjectPortfolio..CovidDeaths
ORDER BY 3, 4;

--SELECT *
--FROM ProjectPortfolio..CovidVaccination
--ORDER BY 3, 4;

SELECT *
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code NOT LIKE 'OWID%'

SELECT country, date, total_cases, new_cases, total_deaths, population
FROM ProjectPortfolio..CovidDeaths
ORDER BY 1, 2;


-- shows percentage of dying if you get covid in your country
-- example: Philippines
SELECT country, date, total_cases, total_deaths, (total_deaths/ NULLIF(total_cases, 0))*100 AS death_percentage
FROM ProjectPortfolio..CovidDeaths
WHERE country LIKE 'Philippines' AND code IS NOT NULL AND code NOT LIKE 'OWID%'
ORDER BY 1, 2;


-- shows what percent of population got covid in your country
-- example: Philppines
SELECT country, date, population, total_cases, (total_cases / population)*100 AS case_percentage
FROM ProjectPortfolio..CovidDeaths
WHERE country LIKE 'Philippines' AND code IS NOT NULL AND code NOT LIKE 'OWID%'
ORDER BY 1, 2;


-- countries with highest infection rate
SELECT country, population, MAX(total_cases) AS highest_infection_count, (MAX(total_cases) / population)*100 AS percent_population_infected
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code NOT LIKE 'OWID%'
GROUP BY country, population
ORDER BY percent_population_infected DESC;


-- countries with highest death count per population
SELECT country, population, MAX(total_deaths) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code NOT LIKE 'OWID%'
GROUP BY country, population
ORDER BY total_death_count DESC;


-- continents with highest death count
SELECT country AS continent, population, MAX(total_deaths) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code LIKE 'OWID%' AND country != 'world'
GROUP BY code, country, population
ORDER BY total_death_count DESC;


-- death percentage all over the world
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deahts, SUM(cast(new_deaths as int))/SUM(NULLIF(new_cases,0))*100 as DeathPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code NOT LIKE 'OWID%'
ORDER BY 1, 2;


-- total amount of people that is vaccinated all around the world (rolling total)
SELECT dea.code, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(cast(new_vaccinations AS NUMERIC)) OVER (PARTITION BY dea.country ORDER BY dea.country, dea.date) AS rolling_people_vaccinated
FROM ProjectPortfolio..CovidDeaths AS dea
JOIN ProjectPortfolio..CovidVaccination AS vac
	ON dea.country = vac.country
	AND dea.date = vac.date
WHERE dea.code IS NOT NULL AND dea.code NOT LIKE 'OWID%'
ORDER BY 2, 3

-- CTE
WITH PopvsVac (code, country, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.code, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER (PARTITION BY dea.country ORDER BY dea.date) AS rolling_people_vaccinated
FROM ProjectPortfolio..CovidDeaths AS dea
JOIN ProjectPortfolio..CovidVaccination AS vac
	ON dea.country = vac.country
	AND dea.date = vac.date
WHERE dea.code IS NOT NULL AND dea.code NOT LIKE 'OWID%'
)
SELECT *, (rolling_people_vaccinated/population)*100 AS population_vaccinated_percentage
FROM PopvsVac;

-- Temp Table
DROP TABLE IF EXISTS #PopulationVaccinatedPercentage
CREATE Table #PopulationVaccinatedPercentage
(
	code NVARCHAR(255),
	country NVARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_people_vaccinated NUMERIC
)

INSERT INTO #PopulationVaccinatedPercentage
SELECT dea.code, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER (PARTITION BY dea.country ORDER BY dea.date) AS rolling_people_vaccinated
FROM ProjectPortfolio..CovidDeaths AS dea
JOIN ProjectPortfolio..CovidVaccination AS vac
	ON dea.country = vac.country
	AND dea.date = vac.date
WHERE dea.code IS NOT NULL AND dea.code NOT LIKE 'OWID%'
SELECT *, (rolling_people_vaccinated/population)*100 AS population_vaccinated_percentage
FROM #PopulationVaccinatedPercentage;


-- create view to store data for later visualizations

CREATE VIEW CovidDyingPercentagePhilippines AS
SELECT country, date, total_cases, total_deaths, (total_deaths/ NULLIF(total_cases, 0))*100 AS death_percentage
FROM ProjectPortfolio..CovidDeaths
WHERE country LIKE 'Philippines' AND code IS NOT NULL AND code NOT LIKE 'OWID%'


CREATE VIEW CovidInfectionPercentagePhilippines AS
SELECT country, date, population, total_cases, (total_cases / population)*100 AS case_percentage
FROM ProjectPortfolio..CovidDeaths
WHERE country LIKE 'Philippines' AND code IS NOT NULL AND code NOT LIKE 'OWID%'


CREATE VIEW CountryHighestInfectionRate AS
SELECT country, population, MAX(total_cases) AS highest_infection_count, (MAX(total_cases) / population)*100 AS percent_population_infected
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code NOT LIKE 'OWID%'
GROUP BY country, population


CREATE VIEW CountryHighestDeathCountPerPop AS
SELECT country, population, MAX(total_deaths) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code NOT LIKE 'OWID%'
GROUP BY country, population


CREATE VIEW CountryHighestDeath AS
SELECT country, population, MAX(total_deaths) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code NOT LIKE 'OWID%'
GROUP BY country, population

CREATE VIEW ContinentHighestDeath AS
SELECT country AS continent, population, MAX(total_deaths) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code LIKE 'OWID%' AND country != 'world'
GROUP BY code, country, population

CREATE VIEW DeathPercentageWorld AS
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deahts, SUM(cast(new_deaths as int))/SUM(NULLIF(new_cases,0))*100 as DeathPercentage
FROM ProjectPortfolio..CovidDeaths
WHERE code IS NOT NULL AND code NOT LIKE 'OWID%'

CREATE VIEW PopulationVaccinatedPercentage AS
SELECT dea.code, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER (PARTITION BY dea.country ORDER BY dea.date) AS rolling_people_vaccinated
FROM ProjectPortfolio..CovidDeaths AS dea
JOIN ProjectPortfolio..CovidVaccination AS vac
	ON dea.country = vac.country
	AND dea.date = vac.date
WHERE dea.code IS NOT NULL AND dea.code NOT LIKE 'OWID%'