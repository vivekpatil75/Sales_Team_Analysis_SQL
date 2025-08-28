create database salesdb;
use salesdb;

CREATE TABLE sales_teams(
	agent_id INT PRIMARY KEY,
    sales_agent VARCHAR(100) NOT NULL,
    manager VARCHAR(100),
    regional_office VARCHAR(20));

CREATE TABLE products (
	product_id INT PRIMARY KEY,
    product_name VARCHAR(25) NOT NULL,
    series VARCHAR(10) NOT NULL,
    sales_price INT NOT NULL);

CREATE TABLE accounts (
	account_id INT PRIMARY KEY,
    account_name VARCHAR(300) NOT NULL,
    sector VARCHAR(100) NOT NULL,
    year_established Date,
    revenue FLOAT,
    employees INT,
    office_location VARCHAR(100),
    subsidiary_of VARCHAR(300));

CREATE TABLE sales_opportunities (
	opportunity_id VARCHAR(8) PRIMARY KEY,
    agent_id INT,
    product_id INT,
    account_id INT,
    deal_stage VARCHAR(50),
    engage_date DATE,
    close_date DATE,
    close_value FLOAT,
    FOREIGN KEY (agent_id) REFERENCES sales_teams(agent_id),
	FOREIGN KEY (product_id) REFERENCES products(product_id),
	FOREIGN KEY (account_id) REFERENCES accounts(account_id));





--LOADING DATA INTO SALES_TEAMS TABLE

BULK INSERT sales_teams
FROM 'C:\temp\sales_teamscsv1.csv'
WITH (
    FIRSTROW = 2,                  -- Skips the header row
    FIELDTERMINATOR = ',',         -- Fields are separated by commas
    ROWTERMINATOR = '\n',
    TABLOCK
);

select * from sales_teams;

--LOADING DATA INTO PRODUCTS TABLE

bulk insert products
from 'C:\temp\products.csv'
with(
	firstrow=2,
	fieldterminator=',',
	rowterminator='\n'
);

select * from products;

--LOADING DATA INTO ACCOUNTS TABLE

bulk insert accounts
from 'C:\temp\accounts.csv'
with(
	firstrow=2,
	fieldterminator=',',
	rowterminator='\n'
);

select * from accounts;

-- loading data for sales_opportunities

bulk insert sales_opportunities
from 'C:\temp\sales_opportunities.csv'
with (
	firstrow=2,
	fieldterminator=',',
	rowterminator='\n'
);

select * from sales_opportunities;

========================================================================================================================

--finding count of deal stages
select deal_stage,count(deal_stage) as count
from sales_opportunities
group by deal_stage;

--finding strength of offices
select regional_office,count(agent_id) as 'No. of sales agents'
from sales_teams
group by regional_office;


--finding how many successful deals done by each salesman
select s.sales_agent,s1.agent_id,count(s1.deal_stage) as won_opportunities 
from sales_opportunities s1
join sales_teams s on s1.agent_id=s.agent_id
where deal_stage='won'
group by s1.agent_id,s.sales_agent
order by count(s1.deal_stage) desc;


-- finding salesman who have not sold anything
SELECT st.regional_office,
        st.manager,
        st.sales_agent
FROM sales_teams st 
WHERE NOT EXISTS (SELECT 1 FROM sales_opportunities sp WHERE sp.agent_id = st.agent_id);




-- finding sales done by each saleman
select s1.sales_agent,count(s2.deal_stage) as won_opportunities,sum(s2.close_value) as Total_Sales
from sales_teams s1
join sales_opportunities s2 on s1.agent_id=s2.agent_id
where s2.deal_stage='won'
group by s1.sales_agent
order by Total_Sales desc;




--calculation sales done by each product
select p.product_name,count(s.product_id) as total_products_sold,sum(s.close_value) as sales_value
from products p
join sales_opportunities s on p.product_id=s.product_id
where s.deal_stage ='won'
group by p.product_name
order by sum(s.close_value) desc;


-- Which products have the highest success rates in closing deals?
SELECT p.product_name,
		ROUND((	SUM(CASE WHEN s.deal_stage = 'Won' THEN 1 ELSE 0 END))*100.0 /
				nullif(SUM(CASE WHEN s.deal_stage IN ('Won','Lost') THEN 1 ELSE 0 END),0), 2) AS success_rate_pct
FROM sales_opportunities s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY success_rate_pct DESC;


--- finding sales by each product and their share 

WITH products_revenue AS (
SELECT p.product_name,
		SUM(s.close_value) AS sales_revenue
FROM sales_opportunities s
JOIN products p ON s.product_id = p.product_id
WHERE s.deal_stage = 'Won'
GROUP BY p.product_name
)
SELECT product_name,
		sales_revenue,
        ROUND((sales_revenue/SUM(sales_revenue) OVER ())*100, 2) AS revenue_pct
FROM products_revenue
ORDER BY sales_revenue DESC;



-- checking which products have the most cancelled deals
select p.product_name,count(s.product_id) as cancelled_deals 
from products p
join sales_opportunities s on p.product_id=s.product_id
where s.deal_stage='lost'
group by p.product_name;


--select max ,min,avg close price for feach product and compairing the sales price
select p.product_name,p.sales_price,max(s.close_value) as max_value,min(s.close_value) as min_value,round(avg(s.close_value),2) as Average_value
from products p
join sales_opportunities s on p.product_id=s.product_id
where s.deal_stage='won'
group by p.product_name,p.sales_price
order by p.product_name;


-- which products sales how much and how much they contribute
with product_sales as(
select p.product_name ,sum(s.close_value) as sales
from sales_opportunities s 
join products p 
on s.product_id=p.product_id
where s.deal_stage='won'
group by p.product_name
)
select *,ROUND(sales*100.0/nullif(sum(sales) over(),0),2) as sales_percentage
from product_sales
order by ROUND(sales*100.0/nullif(sum(sales) over(),0),2) desc,sales desc;



--- analysing accounts table

-- finding no.of accounts from each country
select office_location,count(account_id) as 'No.of Accounts' from accounts
group by office_location
order by count(account_id) desc;


---finding revenue based on sector
select sector,sum(revenue) as 'Sector wise Revenue' from accounts
group by sector
order by sum(revenue) desc;


---finding revenue based on office locations

select office_location,sum(revenue) as 'Location wise Revenue' from accounts
group by office_location
order by sum(revenue) desc;


--finding revenue based on sector for each country
select office_location,sector,sum(revenue) as 'revenue by sector'
from accounts
group by office_location,sector
order by office_location;


--- finding no of employess working in each sector
select sector,sum(employees) as 'Employee Strength' from accounts
group by sector
order by sum(employees) desc;


--finding employess working in each sevtor based oncountry
select office_location,sector,sum(employees) as 'No of Employees' from accounts
group by office_location,sector
order by office_location;


-- finding sales of each sector and its contributuons and success rate
with sector_performance as (
select a.sector as sectors,
sum(case when s.deal_stage='won' then s.close_value else 0 end) as total_sales,
sum(case when s.deal_stage='won' then 1 else 0 end) as won_opp,
sum(case when s.deal_stage in ('won','lost') then 1 else 0 end) as all_opp
from sales_opportunities s
join accounts a 
on s.account_id=a.account_id
group by  a.sector
)
select sectors,total_sales,round(total_sales*100.0/nullif(sum(total_sales) over(),0),2) as sales_percentage,
round(won_opp*100.0/nullif(all_opp,0),2) as success_rate
from sector_performance
order by total_sales desc;



-- finding sales of each sector and its contributuons
with sector_performance as (
select a.sector,sum(s.close_value) as total_sales
from sales_opportunities s
join accounts a 
on s.account_id=a.account_id
where s.deal_stage='won'
group by  a.sector
)
select *,round(total_sales*100.0/nullif(sum(total_sales) over(),0),2) as sales_percentage
from sector_performance
order by total_sales desc;



-- finding sales done by each sales team
select s1.regional_office,s1.manager,COUNT(*) AS won_opportunities,sum(s2.close_value) as 'Revenue by Each Team'
from sales_teams s1
join sales_opportunities s2 on s1.agent_id=s2.agent_id
where s2.deal_stage = 'won'
group by s1.regional_office,s1.manager
order by sum(s2.close_value) desc;


--finding sales team which has highesh success rate in won deals
select s1.regional_office,s1.manager,
round((sum(case when s2.deal_stage='won' then 1 else 0 end )*100.0/nullif(sum(case when s2.deal_stage in ('won','lost') then 1 else 0 end),0)),2) as success_rate
from sales_opportunities s2
join sales_teams s1 on s2.agent_id=s1.agent_id
group by s1.regional_office,s1.manager
order by success_rate desc;


--- finding ranking of agents
select s1.regional_office,s1.manager,s1.sales_agent,
sum(case when s2.deal_stage='won' then s2.close_value else 0 end) as Total_sales_by_Agent,
round(sum(case when s2.deal_stage='won' then 1 else 0 end)*100.0/nullif(sum(case when s2.deal_stage in ('won','lost') then 1 else 0 end),0),2) as success_rate,
DENSE_RANK() over (order by (sum(case when s2.deal_stage='won' then s2.close_value else 0 end)) desc ) as Rank_by_Total_sales,
DENSE_RANK() over (order by (round(sum(case when s2.deal_stage='won' then 1 else 0 end)*100.0/nullif(sum(case when s2.deal_stage in ('won','lost') then 1 else 0 end),0),2)) desc) as Rank_by_Success_Rate
from sales_opportunities s2
join sales_teams s1
on s2.agent_id=s1.agent_id
group by s1.regional_office,s1.manager,s1.sales_agent
order by Total_sales_by_Agent desc,success_rate desc;



--finding success rates of agents and comparing them to team success rate
with sales_data as (
select s1.sales_agent as agent,
s1.manager as team_manager,
s1.regional_office as office,
sum(case when s2.deal_stage='won' then 1 else 0 end) as won_opp,
sum(case when s2.deal_stage in ('won','lost') then 1 else 0 end) as all_opp
from sales_opportunities s2
join sales_teams s1
on s2.agent_id=s1.agent_id
group by s1.regional_office,s1.manager,s1.sales_agent
),
sales_performance as (
select office,team_manager,agent,
won_opp*1.0/nullif(all_opp,0) as agent_success_rate,
sum(won_opp) over(partition by office,team_manager)*1.0/nullif(sum(all_opp) over (partition by office,team_manager),0) as team_success_rate
from sales_data
)
select office,team_manager,agent,
round(agent_success_rate*100,2) as agent_success_rate_pct,
round(team_success_rate*100,2) as team_success_rate_pct,
case when agent_success_rate > team_success_rate then 'Above Average' else 'Below Average' end as 'Agent Performnace'
from sales_performance
order by office,team_manager,agent;



-- Closing Dates information: 
SELECT MIN(close_date) AS first_close_date, 
		MAX(close_date) AS last_close_date
FROM sales_opportunities;


-- quarter trends 

select datepart(quarter,close_date) as quarter_no,
sum(close_value) as sales,
count(*) as won_opp
from sales_opportunities
where deal_stage='won' and close_date is not Null
group by datepart(quarter,(close_date))
order by sales desc;


-- quarter wise growth
with sales_trend as (
select DATEPART(quarter,close_date) as quarters,
sum(close_value) as revenue,
count(*) as won_opp
from sales_opportunities
where deal_stage='won' and close_date is not null
group by datepart(quarter,close_date)
),
quartely_trend as (
select *,
lag(revenue) over (order by quarters) as previous_revenue,
lag(won_opp) over (order by quarters) as previous_won_opp
from sales_trend
)
select quarters,revenue,won_opp,previous_revenue,previous_won_opp,
round((revenue-previous_revenue)*100.0/nullif(previous_revenue,0),2) as revenue_growth,
round((won_opp-previous_won_opp)*100.0/nullif(previous_won_opp,0),2) as won_opp_growth
from quartely_trend;





