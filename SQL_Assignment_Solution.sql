##Task 0
SET GLOBAL sql_mode = 'ONLY_FULL_GROUP_BY';
select @@GLOBAL.sql_mode;
#create schema superstoresDB;
use superstoresDB;
#Tables created using "Table Data Import Wizard".

##Task 1
#A. The superstores database contains 5 tables. Information about them can be found using "select * from table_name" 
#and "describe table_name".
#It contains information about customers, their orders, product and shipping details and market information about the transactions.
#The cust_dimen table contains details about the customers of the superstore such as their names, their provinces, regions 
#and the segments to which they belong along with unique customer ids. All these attributes are of text type.
#The orders_dimen table shows details of different orders placed with their dates and priority. 
#Here, Order_id is integer type and others are text type.
#The prod_dimen table consists information about superstore's available products, with their category and subcategory 
#with all attributes being text type.
#The shipping_dimen table shows details about the shipping of orders given by Order_id, their shipping modes and dates of shipping.
#As mentioned, Order_id is of integer type and all other attributes are text type.
#The market_fact table contains information about market facts for all products, customers ordering those products 
#and shipping details. Ord_id (text type) identifies orders, Prod_id (text type) identifies the product, Ship_id (text type) 
#shows shipping details, Cust_id (text type) tells about the customer who ordered the given product, product Sales and
#Discount (both double type), order quantity (integer type), superstore's profit (double type), cost of shipping (double type) and 
#margin on the product base (double type) are given. In other words, this table contains sales, shipping and profits information for 
#for given order, product, customer and shipping.
#This database can be used to get facts and insights about the superstore's transactions such as
#the sales, profits, or the quantities ordered across different product categories or regions or shipping modes.

#B. Table				Primary key				Foreign keys					
#	cust_dimen			Cust_id					NA
#   order_dimen			Ord_id					Order_id
#	shipping_dimen		Ship_id					Order_id
#	prod_dimen			Prod_id					NA
#	market_fact			NA						Cust_id, Ord_id, Ship_id, Prod_id
#
#For primary key, "select count(distinct(primary_key)) from table_name" should give the total number of rows. 
#(Unique primary key for each record)
#In order_dimen, Order_id in not unique, while Ord_id is.
#Order_id can be used as foreign key to join order_dimen and shipping_dimen tables.
#For market_fact table (Ord_id, Sales) can uniquely determine a record in the given table but it's not intuitive to use such a pair as 
#primary key. 

##Task 2
#A. Find the total and the average sales (display total_sales and avg_sales).

#Rounding to 2 decimal digits for better presentation
select round(sum(Sales),2) as Total_sales, round(avg(Sales),2) as Average_sales
from market_fact;


#B. Display the number of customers in each region in decreasing order of no_of_customers. 
#The result should contain columns Region, no_of_customers.
select Region, count(*) as No_of_customers
from cust_dimen
group by Region
order by no_of_customers desc;


#C. Find the region having maximum customers (display the region name and max(no_of_customers).

#The having clause is used so that the max_no_of_customers should be greater than all the counts of customers across different regions.
select Region, count(*) as Max_no_of_customers
from cust_dimen
group by Region
having max_no_of_customers >= all(select count(*) 
									from cust_dimen 
                                    group by Region);

#This query can also be written as following: (Limiting the number of records to one in query of question B)
select Region, count(*) as Max_no_of_customers
from cust_dimen
group by Region
order by Max_no_of_customers desc
limit 1;


#D. Find the number and id of products sold in decreasing order of products sold (display product id, no_of_products sold).
select Prod_id, sum(Order_quantity) as No_of_products_sold
from market_fact
group by prod_id
order by no_of_products_sold desc;


#E. Find all the customers from Atlantic region who have ever purchased ‘TABLES’ and the number of tables purchased.
#(display the customer name, no_of_tables purchased)

#Firstly, cust_dimen and market_fact table is joined to get Cust_id and aggregate order quantity for each customer id
#Prod_id is found using where clause on prod_dimen table
#The resulting subtable is then again joined with the cust_dimen table to get the names of the customers 
#Order by decreasing number of table purchased is done for better presentation
select c1.Customer_name, subtable.No_of_tables_purchased
from cust_dimen c1
	inner join
		(select c2.Cust_id as Customer_id, sum(mf.Order_quantity) as No_of_tables_purchased
		from cust_dimen c2
			inner join market_fact mf on c2.Cust_id = mf.Cust_id
		where Prod_id = (select Prod_id 
						from prod_dimen
                        where Product_Sub_Category='TABLES') and
			  c2.Region = 'Atlantic'
		group by mf.Cust_id) subtable
	on c1.Cust_id = subtable.Customer_id
order by subtable.No_of_tables_purchased desc;
    
#This query can be much easier if we group by Customer_name instead of Cust_id, but Customer_name is not unique.
#Grouping by Customer_name can be done as follows:
select c.Customer_name as Customer_name, sum(mf.Order_quantity) as No_of_tables_purchased
from cust_dimen c
	inner join market_fact mf on c.Cust_id = mf.Cust_id
where Prod_id = (select Prod_id 
				from prod_dimen
				where Product_Sub_Category='TABLES') and
	  c.Region = 'Atlantic'
group by c.Customer_name
order by No_of_tables_purchased desc;


##Task 3
#A. Display the product categories in descending order of profits. 
#(display the product category wise profits i.e. product_category, profits)?

#prod_dimen table is joined with market_fact table and profits are aggregated for each product category
#Rounding to 2 decimal digits for better presentation
select p.Product_Category, round(sum(mf.Profit),2) as Profits
from prod_dimen p 
	inner join market_fact mf on p.Prod_id = mf.Prod_id
group by p.Product_Category
order by Profits desc;


#B. Display the product category, product sub-category and the profit within each subcategory in three columns.

# Group by is used on both product category and sub category just in case there are same sub categories in two different categories.
#Rounding to 2 decimal digits for better presentation
#Ordered in ascending order to use the information for the next question
select p.Product_Category, p.Product_Sub_Category, round(sum(mf.Profit),2) as Profits
from prod_dimen p 
	inner join market_fact mf on p.Prod_id = mf.Prod_id
group by p.Product_Category, p.Product_Sub_Category
order by Profits asc;


#C. Where is the least profitable product subcategory shipped the most? For the least profitable product sub-category, 
#display the region-wise no_of_shipments and the profit made in each region in decreasing order of profits (i.e. region,
#no_of_shipments, profit_in_each_region)
#Note: You can hardcode the name of the least profitable product subcategory

#From the last question, the name of the least profitable product subcategory = "TABLES"
#The following query is used to answer the first question, The least profitable product subcategory is shipped most to the "ONTARIO" region.
select c.Region, count(mf.Ship_id) as No_of_shipments, sum(mf.Profit) as Profit_in_each_region
from market_fact mf 
	inner join cust_dimen c on c.Cust_id = mf.Cust_id
where mf.Prod_id = (select Prod_id 
					from prod_dimen 
					where Product_Sub_Category = 'TABLES')
group by c.Region
order by No_of_shipments desc;

#The following query is used to order the records in decreasing order of profits
select c.Region, count(mf.Ship_id) as No_of_shipments, sum(mf.Profit) as Profit_in_each_region
from market_fact mf 
	inner join cust_dimen c on c.Cust_id = mf.Cust_id
where mf.Prod_id = (select Prod_id 
					from prod_dimen 
					where Product_Sub_Category = 'TABLES')
group by c.Region
order by Profit_in_each_region desc;

#If the least profitable product subcategory is not known: (Join cust_dimen, market_fact, and prod_dimen
#and find the least profitable subcategory in a sub query is where clause)
select c.Region, count(mf.Ship_id) as No_of_shipments, sum(mf.Profit) as Profit_in_each_region
from cust_dimen c
	inner join market_fact mf on c.Cust_id = mf.Cust_id
	inner join prod_dimen p on p.Prod_id = mf.Prod_id
where p.Product_sub_category = (select Product_sub_category 
								from prod_dimen p1
									inner join market_fact mf1 on mf1.Prod_id = p1.Prod_id
								group by p1.Product_sub_category
                                order by sum(mf1.Profit)
                                limit 1)
group by c.Region
order by Profit_in_each_region desc;