--daateadd,case,rank,cast function

use Zomato

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;



--1.Total amount of money spent by each customer

select sum(b.price) as total_amount_spent ,a.userid 
from sales a 
inner join product b on a.product_id=b.product_id
group by a.userid


--2.How many days a customer visited zomato ??

select userid, count(distinct(created_date)) as days_visited 
from sales
group by userid


--3.First product purchased by each customer

select a.userid,a.created_date,a.product_id,b.product_name
from sales a
inner join product b on a.product_id=b.product_id
where userid=1
order by created_date

--rank function
--we can see the product id of the customer is 1 who ordered their first product.

select*,rank() over(partition by userid order by created_date) rnk from Zomato.dbo.sales 


--4.what is most purchased item o the menu and how many times was it purchased by all customers.

select  product_id,count(userid) as No_of_users_purchased 
from sales
group by product_id
order by No_of_users_purchased desc



---brought by customers how many times.

select userid,count(product_id) as No_of_times_purchased
from sales
where product_id=


(select  top 1 product_id
from sales
group by product_id
order by count(userid)  desc)

group by userid


--5.Which item was most popular for each customer.

select product_id, count(product_id) as No_of_times_each_productpurchased
from sales
where userid=1
group by product_id
order by No_of_times_each_productpurchased desc


---for all customers.

select userid,product_id,count(product_id) as No_of_times_product_purchased
from sales
group by userid,product_id


--precise answer
--a and b are alias ---read more about them.
select* from
(select*,rank() over(partition by userid order by  No_of_times_product_purchased desc) rnk from
(select userid,product_id,count(product_id)  No_of_times_product_purchased from sales group by userid,product_id)a)b
where rnk=1


--6.Which item was purchased first by the container after they became a member
select a.userid ,b.product_id,b.created_date,a.gold_signup_date
from goldusers_signup a
left join sales b on a.userid=b.userid
where b.created_date>=a.gold_signup_date

--giving rank
select* from
(select*,rank() over(partition by a.userid order by a.created_date) rnk from
(select a.userid ,b.product_id,b.created_date,a.gold_signup_date
from goldusers_signup a
left join sales b on a.userid=b.userid
where b.created_date>=a.gold_signup_date)a)b 
where rnk=1


--7.Which item was purchased just before customer became a member.
select* from
(select*,rank() over(partition by a.userid order by a.created_date) rnk from
(select a.userid ,b.product_id,b.created_date,a.gold_signup_date
from goldusers_signup a
left join sales b on a.userid=b.userid
where b.created_date<a.gold_signup_date)a)b 
where rnk=1

--8.What is total orders and amount spent for each member before they became a member

select g.userid , s.product_id,count(s.product_id) as total_orders,sum(p.price) as total_price
from  sales s 
right join goldusers_signup g on g.userid=s.userid
inner join product p on s.product_id =p.product_id
where s.created_date<g.gold_signup_date
group by g.userid,s.product_id



--precise answer
select g.userid ,count(s.product_id) as total_orders,sum(p.price) as total_price
from  sales s 
right join goldusers_signup g on g.userid=s.userid
inner join product p on s.product_id =p.product_id
where s.created_date<g.gold_signup_date
group by g.userid


--9.Calculate points scored by the customer basis on conditions
--also calculate extra cashback they recieve...if 5rs =2 zomato point.


select userid,sum(total_points)*2.5 as total_cashback from
(select s.userid , s.product_id,count(s.product_id) as total_orders,sum(p.price) as total_price,
case when s.product_id=1 then (sum(p.price)/5)*1 
when s.product_id=2 then (sum(p.price)/10)*5
when s.product_id=3 then (sum(p.price)/5)*1
end as total_points
from  sales s 
inner join product p on s.product_id =p.product_id
group by s.userid,s.product_id)a
group by userid

--10.In the first year after a customer joins the gold programs irrespective of what the customer has purchased they earn 5 zomato points for every 10rs spent 
--Who earned more 1 or 3? and what was their points earnings in first year?


select g.userid,(sum(p.price)/10)*5 as total_points_earned
from sales s 
right join goldusers_signup g on s.userid=g.userid
inner join product p on s.product_id=p.product_id
where s.created_date>=g.gold_signup_date and s.created_date<= DATEADD(year, 1, g.gold_signup_date)
group by g.userid
order by total_points_earned desc


--11.Rank all transactions of customer based on price spent on each product

select*,rank() over(partition by userid order by total_amount desc) rank1 from
(select s.userid,s.product_id,sum(p.price) as total_amount
from sales s
inner join product p on s.product_id=p.product_id
group by s.userid ,s.product_id)a

--precise ie only first
select* from
(select* , rank() over (partition by userid order by total_price desc ) rank from
(select s.userid,s.product_id,count(s.product_id) astimes_ordered ,sum(p.price) as total_price
from sales s
inner join product p on s.product_id=p.product_id
group by s.userid,s.product_id)a)b
where rank=1


--13.rank all transactions of member of gold and for non members transactions as na
 
select e.*,case when rnk=0 then 'na' else rnk end as rnkk from
(select c.*,cast((case when gold_signup_date is null then 0 else rank() over (partition by userid order by created_date desc)end)as varchar)as rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a left join
goldusers_signup b on a.userid=b.userid and created_date>=gold_signup_date)c)e


