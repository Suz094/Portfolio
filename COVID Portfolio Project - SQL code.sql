-- Data Cleaning in SQL
-- 	- Split data into 2 excel files: coviddeaths and covidvaccinations
-- 	- Cleaned the data: 
-- 		- Changed date format to yyyy-mm-dd
-- 		- Replaced all blank fields with NULL

-- SQL CODE
-- USE portfolio_project;
-- CREATE TABLE covidDeaths
-- (
-- 	iso_code varchar(20), continent varchar(30), location varchar(50), date date,
-- 	total_cases int, new_cases int, new_cases_smoothed double, total_deaths int, new_deaths int,
--     new_deaths_smoothed	double, total_cases_per_million	double, new_cases_per_million double,
--     new_cases_smoothed_per_million double, total_deaths_per_million double, new_deaths_per_million double,
--     new_deaths_smoothed_per_million	double, reproduction_rate double, icu_patients int, 
--     icu_patients_per_million double, hosp_patients int, hosp_patients_per_million  double,
--     weekly_icu_admissions int, weekly_icu_admissions_per_million double, weekly_hosp_admissions int,
--     weekly_hosp_admissions_per_million double
-- );

-- ALTER TABLE coviddeaths
-- ADD COLUMN population int;

-- CREATE TABLE covidVaccinations
-- (
-- 	iso_code varchar(20), continent varchar(30), location varchar(50), date date,
--     total_tests	int, new_tests int, total_tests_per_thousand double, new_tests_per_thousand	double,
--     new_tests_smoothed int, new_tests_smoothed_per_thousand	double, positive_rate double,
--     tests_per_case double, tests_units	varchar(25), total_vaccinations int, people_vaccinated int,
--     people_fully_vaccinated	int, total_boosters int, new_vaccinations int, new_vaccinations_smoothed int,
--     total_vaccinations_per_hundred	double, people_vaccinated_per_hundred double,
--     people_fully_vaccinated_per_hundred	double, total_boosters_per_hundred double,
--     new_vaccinations_smoothed_per_million int, new_people_vaccinated_smoothed int,
--     new_people_vaccinated_smoothed_per_hundred int, stringency_index double, population_density	double,
--     median_age double, aged_65_older double, aged_70_older double, gdp_per_capita double, 
--     extreme_poverty double,	cardiovasc_death_rate double, diabetes_prevalence double, female_smokers double,
--     male_smokers double, handwashing_facilities double,	hospital_beds_per_thousand double,
--     life_expectancy	double, human_development_index	double, excess_mortality_cumulative_absolute double,
--     excess_mortality_cumulative	double, excess_mortality double,
--     excess_mortality_cumulative_per_million double
-- );

---------------------------------------

-- SELECT *
-- FROM portfolio_project.coviddeaths
-- ORDER BY 3,4;

-- SELECT *
-- FROM portfolio_project.covidvaccinations
-- ORDER BY 3,4;

-- SELECT location, date, total_cases, new_cases, total_deaths, population
-- FROM portfolio_project.coviddeaths
-- ORDER BY location, date;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in India/North America/Australia/Kuwait

SELECT Location, Date, Total_cases, Total_deaths,
	(total_deaths/total_cases)*100 AS Percentage_of_Deaths
FROM portfolio_project.coviddeaths
WHERE location IN ('India', 'North America', 'Australia', 'Kuwait') 
AND continent IS NOT NULL
ORDER BY location, date;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT Location, Date, Total_cases, Population,
	(total_cases/population)*100 AS Covid_Percentage
FROM portfolio_project.coviddeaths
WHERE location IN ('India', 'North America', 'Australia', 'Kuwait') 
AND continent IS NOT NULL
ORDER BY location, date;

-- Looking at countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(Total_cases) AS Highest_Infection_Count, 
	MAX((total_cases/population))*100 AS Percentage_Population_Infected
FROM portfolio_project.coviddeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY Percentage_Population_Infected desc;

-- Showing countries with Highest Death Count per Population

SELECT Location, MAX(total_deaths) AS Total_Death_Count
FROM portfolio_project.coviddeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY Total_Death_Count desc;

-- Breaking things down by continents

-- Showing continents with the highest death count per population

-- SELECT location, MAX(total_deaths) AS Total_Death_Count
-- FROM portfolio_project.coviddeaths
-- WHERE continent IS NULL
-- GROUP BY location
-- ORDER BY Total_Death_Count desc;

SELECT continent, MAX(total_deaths) AS Total_Death_Count
FROM portfolio_project.coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count desc;


-- GLOBAL NUMBERS 

-- Percentage of Deaths globally

SELECT SUM(new_cases) AS Total_New_Cases, SUM(new_deaths) AS Total_New_Deaths,
	SUM(total_deaths)/SUM(total_cases)*100 AS Percentage_of_Deaths
FROM portfolio_project.coviddeaths
-- WHERE location IN ('India', 'North America', 'Australia', 'Kuwait') 
WHERE continent IS NOT NULL AND new_deaths IS NOT NULL
-- GROUP BY date
ORDER BY date;

-- Percentage of Deaths globally grouped by date

SELECT Date, SUM(new_cases) AS Total_New_Cases, SUM(new_deaths) AS Total_New_Deaths,
	SUM(total_deaths)/SUM(total_cases)*100 AS Percentage_of_Deaths
FROM portfolio_project.coviddeaths
-- WHERE location IN ('India', 'North America', 'Australia', 'Kuwait') 
WHERE continent IS NOT NULL AND new_deaths IS NOT NULL
GROUP BY date
ORDER BY date;

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM portfolio_project.coviddeaths dea
JOIN portfolio_project.covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- With CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM portfolio_project.coviddeaths dea
JOIN portfolio_project.covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
)
SELECT *, (Rolling_People_Vaccinated/population)*100
FROM PopvsVac

---------------

-- Find the location that has the Max People vaccinated using CTE

-- WITH PopvsVac (Continent, Location, Population, New_Vaccinations, Rolling_People_Vaccinated)
-- AS
-- (
-- SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations,
-- 	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location) AS Rolling_People_Vaccinated
-- FROM portfolio_project.coviddeaths dea
-- JOIN portfolio_project.covidvaccinations vac
-- 	ON dea.location = vac.location
-- 	AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3
-- )
-- SELECT *, MAX(Rolling_People_Vaccinated)-- , MIN(Rolling_People_Vaccinated/population)*100
-- FROM PopvsVac

-------------------------

-- With TEMP Table

DROP TABLE IF EXISTS PercentPopulationVaccinated -- (if it already exists) 

CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
	Continent varchar(55), Location varchar(55), Date date, Population int,
    New_Vaccinations int, Rolling_People_Vaccinated double
)
AS
(	
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
	FROM portfolio_project.coviddeaths dea
	JOIN portfolio_project.covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3
);

SELECT *, (Rolling_People_Vaccinated/population)*100 AS Rolling_Percent_People_Vaccinated
FROM PercentPopulationVaccinated

-- Creating View to store data for later visualisations

CREATE VIEW PercentPopulationVaccinated AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
	FROM portfolio_project.coviddeaths dea
	JOIN portfolio_project.covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3
)

SELECT *
FROM percentpopulationvaccinated
