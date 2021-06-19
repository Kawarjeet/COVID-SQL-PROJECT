select *
from PortfolioProject..CovidDeaths
order by 3,4

--selecting  data that we are going to use in our project
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths -- we could have also used PortfolioProject.dbo.CovidDeaths ; dbo stands for database owner is a microsoft schema
order by location, date --sorts data in ascending order first by location and if the location is same then sorts by date in ascending order.

--Looking at Total cases vs Total Deaths in terms of percentage
-- shows likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%india%'
order by location, date

--looking at the total cases vs the population
-- shows what percentage of the popoulation has contracted covid
select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths	
--where location like '%states%'
order by location, date

--looking at countries with highest infection rate wrt to population
select location, population, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%india%'
Group by location, population
order by PercentPopulationInfected desc

--looking at countries with highest death count in a day

select location, max(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null --we do not want the continent count and just the countries count
group by location --we use group by as we used the operator max 
order by HighestDeathCount desc  -- orders the list by highest death count in descending order, the default is ascending


-- figuring out the global numbers (sum  of cases of all the countries by date) in death percentage
select date, sum(new_cases) as TotalNewCasesOnDate,  sum(cast(new_deaths as int)) as TotalNewDeathOnDate, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage 
from PortfolioProject..CovidDeaths
where continent is not null
group by date	
order by 1,2


 
 --figuring out the total cases and total deaths in death percentage
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as int))/ sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


-- Joining CovidDeaths and CovidVaccinations on location and date
select * 
from PortfolioProject..CovidVaccinations vac --giving it an alias name vac so that we dont have to type out entire thing again and again
Join PortfolioProject..CovidDeaths dea -- dea is the alias name
on vac.location = dea.location
and vac.date=dea.date
where vac.continent is not null
and vac.continent like '%Asia%'
order by 2,3


--looking at total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidVaccinations vac --giving it an alias name vac so that we dont have to type out entire thing again and again
Join PortfolioProject..CovidDeaths dea -- dea is the alias name
on vac.location = dea.location
and vac.date=dea.date
where vac.continent is not null
--and vac.continent like '%Asia%'
order by 1,2,3

--looking at increase in vaccination count across the globe by date
select dea.date, sum(cast(vac.new_vaccinations as int)) as TotalVaccinationsOnDate
from PortfolioProject..CovidVaccinations vac --giving it an alias name vac so that we dont have to type out entire thing again and again
Join PortfolioProject..CovidDeaths dea -- dea is the alias name
on vac.location = dea.location
and vac.date=dea.date
where vac.continent is not null
--and vac.continent like '%Asia%'
group by dea.date
order by 1

with popvsvac(continent, location, date, population, new_vaccinations, cumulativevaccinations)
-- the no of arguments should be the same as that in select statement else its an error
as 
(
	--looking at increase in vaccination count by country
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations))
	over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccinations
	--, (CumulativeVaccinations/dea.population)*100     -- this will give an error for invalid column name 'CumulativeVaccinations'
	-- so we use CTE to sort out this issue
	from PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	and dea.location like '%albania%' -- finding the total vaccinations on cumulative basis by date
	--order by 1,2   -- order by cannot come inside a CTE
)
	select *, (cumulativevaccinations/population)*100 as CumulativeVaccinationPercentage
	from popvsvac
	order by 1,2
	-- 

-- performing the above CTE operations using a temp table as below
drop table if exists #cumulativevaccinationspercentage
create table #cumulativevaccinationspercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulativevaccinations numeric
)

insert into #cumulativevaccinationspercentage
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations))
	over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccinations
	--, (CumulativeVaccinations/dea.population)*100     -- this will give an error for invalid column name 'CumulativeVaccinations'
	-- so we use CTE to sort out this issue
	from PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	and dea.location like '%albania%' -- finding the total vaccinations on cumulative basis by date
	order by 1,2   -- order by cannot come inside a CTE

	select *, (cumulativevaccinations/population)*100 as CumulativeVaccinationPercentage
	from #cumulativevaccinationspercentage


--creating view for the above operations
create view cumulativepopulationvaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations))
	over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccinations
	--, (CumulativeVaccinations/dea.population)*100     -- this will give an error for invalid column name 'CumulativeVaccinations'
	-- so we use CTE to sort out this issue
	from PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	and dea.location like '%albania%' -- finding the total vaccinations on cumulative basis by date

	select *		-- now we can directly use the view the we created 
	from cumulativepopulationvaccinated
