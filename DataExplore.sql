SELECT *
FROM coviddeath
WHERE LEFT(iso_code, 4) != 'OWID'
ORDER BY 3,4;

-- select data that are going to be used

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM coviddeath ORDER BY 1,2;

-- looking at total cases vs total deaths

SELECT Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS death_percentage
FROM coviddeath
WHERE location = 'Denmark'
ORDER BY 1,2;

-- looking at total cases vs. population

SELECT Location, date, total_cases, population, ROUND((total_cases/population)*100,2) AS confirm_percentage
FROM coviddeath
WHERE location = 'Denmark'
ORDER BY 1,2;

-- looking at countries with highest infection rate compared to population

SELECT Location, population, max(total_cases) AS HighestInfection, ROUND((max(total_cases)/population)*100,2)
AS HighestPercentage
FROM coviddeath
GROUP BY Location, population
ORDER BY HighestInfection DESC;

-- looking at countries with highest death count per population
-- eleminate the number of continent

SELECT Location, CAST(MAX(total_deaths) AS signed) AS TotalDeathCount
FROM coviddeath
WHERE LEFT(iso_code, 4) != 'OWID'
GROUP BY Location
ORDER BY 1 ASC;

-- showing the continent with the highest death cases

/*
SELECT iso_code, Location
FROM coviddeath
WHERE LEFT(iso_code, 4) = 'OWID'
GROUP BY iso_code, Location
ORDER BY 1 ASC;
*/

-- global numbers

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as signed)) as total_deaths, 
ROUND((SUM(CAST(new_deaths as signed))/SUM(new_cases))*100,2) AS DeathPercentage
FROM coviddeath
WHERE continent != ""
GROUP BY 1
ORDER BY 1,2;

SELECT d.continent, d.Location, d.date, d.population, CAST(v.new_vaccinations as signed) new_vaccinations,
SUM(v.new_vaccinations) OVER (Partition BY d.location ORDER BY d.date) AS roll_new_vacc
FROM coviddeath d
JOIN covidvaccination v
ON d.Location = v.location
AND d.date = v.date
WHERE d.continent != ""
ORDER BY 2,3;


With PopvsVac (Continent, Location, Date, Population, new_vaccinations, roll_new_vacc)
AS
(
SELECT d.continent, d.Location, d.date, d.population, CAST(v.new_vaccinations as signed) new_vaccinations,
SUM(v.new_vaccinations) OVER (Partition BY d.location ORDER BY d.date) AS roll_new_vacc
FROM coviddeath d
JOIN covidvaccination v
ON d.Location = v.location
AND d.date = v.date
WHERE d.continent != ""
)
SELECT * FROM PopvsVac;

-- temp table

DROP Table if exists PercentPopulationVaccination;
Create Table PercentPopulationVaccination
(
Continent varchar(255),
Location varchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
roll_new_vacc numeric
);
Insert ignore into PercentPopulationVaccination 
SELECT d.continent, d.Location, d.date, d.population, CAST(v.new_vaccinations as signed integer) new_vaccinations,
SUM(v.new_vaccinations) OVER (Partition BY d.location ORDER BY d.date) AS roll_new_vacc
FROM coviddeath d
JOIN covidvaccination v
ON d.Location = v.location
AND d.date = v.date
WHERE d.continent != "";
SELECT *, ROUND((roll_new_vacc/Population) * 100,2) roll_new_vacc_per
FROM PercentPopulationVaccination;

-- creat views for visualizations

Create View PercentPopulationVaccinations AS
SELECT d.continent, d.Location, d.date, d.population, CAST(v.new_vaccinations as signed integer) new_vaccinations,
SUM(v.new_vaccinations) OVER (Partition BY d.location ORDER BY d.date) AS roll_new_vacc
FROM coviddeath d
JOIN covidvaccination v
ON d.Location = v.location
AND d.date = v.date
WHERE d.continent != "";

SELECT * FROM PercentPopulationVaccinations;