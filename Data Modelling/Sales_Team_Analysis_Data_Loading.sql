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