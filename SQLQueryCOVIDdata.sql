-- The total percentage of covid cases vs total deaths
--Shows the likelood of dying if covid contracted by country 
SELECT location, total_cases, total_deaths, round( (cast(total_deaths as float) /cast(total_cases as float) * 100) , 2) as deathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Total cases vs population, shows the percentage of population that has been affected
SELECT location, total_cases, population, round( (cast(total_cases as float) /cast(population as float) * 100) , 2) as infectionRate
FROM coviddeaths 
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Looking at the countries with the highest infection rate per population and total cases
select location, population, max(total_cases) as peak_cases, max(round( (cast(total_cases as float) /cast(population as float) * 100) , 2)) as InfectionRate
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY [location], population
ORDER BY infectionRate DESC;

--Looking at the countries with the most deaths
SELECT location, population, max(total_deaths) as totaldeaths
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY [location], population
ORDER BY totaldeaths DESC;

--The number of new cases and deaths within the last year in NZ, compared to the year before
SELECT currentyear.[location], caseswithintheyear, caseslastyear, deathswithintheyear, deathslastyear 
FROM (SELECT coviddeaths.location, sum(new_cases) as caseswithintheyear, sum(new_deaths) as deathswithintheyear  
        FROM coviddeaths
        WHERE [date] BETWEEN '2022-02-01' AND '2023-02-01' and coviddeaths.[iso_code] = 'NZL'
        GROUP BY coviddeaths.[location]) currentyear
INNER JOIN (SELECT coviddeaths.[location], sum(new_cases) as caseslastyear, sum(new_deaths) as deathslastyear  
        FROM coviddeaths
        WHERE [date] BETWEEN '2021-02-01' AND '2022-02-01' and coviddeaths.iso_code = 'NZL'
        GROUP BY coviddeaths.[location]) previousyear
ON currentyear.[location] = previousyear.[location]

--Total deaths by continent
SELECT location, population, max(total_deaths) as totaldeaths
FROM coviddeaths
WHERE continent IS NULL
GROUP BY [location], population
HAVING [location] not like '%income' AND location not in ('World', 'International')
ORDER BY totaldeaths DESC;

--Looking at the total vaccinations, cases and deaths by country, comparing the total percentage of the population vaccinated with the total percentage of deaths
WITH totals AS
(SELECT d.location, population, max(total_cases) as TotalCases, max(total_deaths) TotalDeaths, max(people_vaccinated) AS TotalVaccinations
FROM coviddeaths d
INNER JOIN covidvaccinations v
ON d.iso_code = v.iso_code
WHERE d.continent IS NOT NULL
GROUP BY d.location, population)

SELECT *, (cast(TotalDeaths as float)/population)*100 as DeathPercentage, (TotalVaccinations/population)*100 as VaccinationPercentage
FROM totals;

--Rolling percentage of vaccinations and vaccination percentage by date and country
WITH vaccinationpercentage AS (SELECT d.location, population, total_cases, total_deaths, new_vaccinations,
sum(new_vaccinations) OVER (Partition by d.location ORDER by d.date) as total_vaccs
FROM coviddeaths d 
INNER JOIN covidvaccinations v 
ON d.iso_code = v.iso_code and d.date = v.date
WHERE d.continent IS NOT NULL)
SELECT *, (total_vaccs/population) AS Vaccinations_Percentage FROM 
vaccinationpercentage;

--Creating a view of previous query

CREATE VIEW RollingPercentagePeopleVaccinated AS
SELECT d.location, population, total_cases, total_deaths, new_vaccinations,
sum(new_vaccinations) OVER (Partition by d.location ORDER by d.date) as total_vaccs
FROM coviddeaths d 
INNER JOIN covidvaccinations v 
ON d.iso_code = v.iso_code and d.date = v.date
WHERE d.continent IS NOT NULL;