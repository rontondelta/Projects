-- COVID DEATH DATASET --

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4;

-- Select Data that we will be using

SELECT location, date, total_cases, new_cases ,total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid-19 in India
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'India'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows percentage of population that contracted Covid-19
SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'India'
ORDER BY 1,2;

-- Looking at Countries with Highest Infection as compared to Population
SELECT location, MAX(total_cases) as PeakCaseCount, population, MAX((total_cases/population)*100) as PeakInfectedPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PeakInfectedPercentage DESC;

-- Countries with Highest Death Count
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Continents with Highest Death Count
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

---- Incorrect Version of Continent Separation
---- Showing the continents with the highest death count per population
--SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
--FROM PortfolioProject..CovidDeaths
--WHERE continent is not NULL
--GROUP BY continent
--ORDER BY TotalDeathCount DESC;



--GLOBAL NUMBERS

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths
, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths
, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1


-- COVID VACCINATIONS DATASET --

-- Looking at Total Population vs Vaccinations with a rolling count for
-- Total Vaccinations partitioned by location
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not NULL

-- USE CTE (Common Table Expressions)

WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingVacCount)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not NULL
)
SELECT *, (RollingVacCount/population) * 100 as PercentageVaccinated
From PopvsVac

-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVacCount numeric
)
INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
dea.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not NULL 

SELECT *, (RollingVacCount/population) * 100 as PercentageVaccinated
From #PercentPopulationVaccinated


-- Creating View to store data for Visualizations

Create View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
  dea.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not NULL 
