---- Alter column type
--ALTER TABLE [Portfolio Project]..covidvaccinations
--	ALTER COLUMN new_vaccinations FLOAT

-- Total Cases vs. Total Deaths
SELECT location
	,date
	,total_deaths
	,total_cases
	,total_deaths / total_cases
FROM [Portfolio Project]..coviddeaths
WHERE location = 'United States'
	and continent IS NOT NULL
ORDER BY 'location'
	,'date'

-- Total Cases vs. Population in US
SELECT location
	,date
	,population
	,total_cases
	,total_cases / population
FROM [Portfolio Project]..coviddeaths
WHERE location = 'United States'
	and continent IS NOT NULL
ORDER BY 'location'
	,'date'

-- Countries with highest infection rate compared to population
SELECT location
	,population
	,MAX(total_cases) AS highest_infection_count
	,MAX(total_cases) / population AS infected_percentage
FROM [Portfolio Project]..coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
	,population
ORDER BY MAX(total_cases) / population DESC

--  Showing countries with highest death count per population
SELECT location
	,MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM [Portfolio Project]..coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Death count by continent
SELECT continent
	,MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM [Portfolio Project]..coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- Global numbers per day
SELECT date
	,SUM(new_cases) AS total_cases
	,SUM(new_deaths) AS total_deaths
	,SUM(new_deaths) / NULLIF(SUM(new_cases),0) AS death_percentage
FROM [Portfolio Project]..coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

-- Global numbers
SELECT SUM(new_cases) AS total_cases
	,SUM(new_deaths) AS total_deaths
	,(SUM(new_deaths) / NULLIF(SUM(new_cases),0)) AS death_percentage
FROM [Portfolio Project]..coviddeaths
WHERE continent IS NOT NULL

-- Total population vs. vaccinations
SELECT dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,SUM(vac.new_vaccinations) OVER (
		PARTITION BY dea.location ORDER BY dea.location
			,dea.date
		) AS rolling_vaccinations

FROM [Portfolio Project]..coviddeaths dea
JOIN [Portfolio Project]..covidvaccinations vac ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location
	,dea.date

-- Use CTE
WITH pop_vs_vac (
	continent
	,location
	,date
	,population
	,new_vaccinations
	,rolling_vaccinations
	)
AS (
	SELECT dea.continent
		,dea.location
		,dea.date
		,dea.population
		,vac.new_vaccinations
		,SUM(vac.new_vaccinations) OVER (
			PARTITION BY dea.location ORDER BY dea.location
				,dea.date
			) AS rolling_vaccinations
	FROM [Portfolio Project]..coviddeaths dea
	JOIN [Portfolio Project]..covidvaccinations vac ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	)
SELECT *
	,rolling_vaccinations / population * 100
FROM pop_vs_vac

-- Temp Table
DROP TABLE

IF EXISTS #percent_population_vaccinated
	CREATE TABLE #percent_population_vaccinated (
		continent NVARCHAR(255)
		,location NVARCHAR(255)
		,dare DATETIME
		,population NUMERIC
		,new_vaccinations NUMERIC
		,rolling_vaccinations NUMERIC
		)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,SUM(vac.new_vaccinations) OVER (
		PARTITION BY dea.location ORDER BY dea.location
			,dea.date
		) AS rolling_vaccinations
FROM [Portfolio Project]..coviddeaths dea
JOIN [Portfolio Project]..covidvaccinations vac ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *
	,rolling_vaccinations / population * 100
FROM #percent_population_vaccinated

--Creating view for data visualization
--USE [Portfolio Project]
CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,SUM(vac.new_vaccinations) OVER (
		PARTITION BY dea.location ORDER BY dea.location
			,dea.date
		) AS rolling_vaccinations
FROM [Portfolio Project]..coviddeaths dea
JOIN [Portfolio Project]..covidvaccinations vac ON dea.location = vac.location
	AND dea.date = vac.date

Select*
from percent_population_vaccinated