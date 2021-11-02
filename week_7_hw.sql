--1.	Create a new column called “status” in the rental table that uses a case statement to indicate if a 
--    film was returned late, early, or on time.
--First add the status column to the rental table using ALTER TABLE command.
ALTER TABLE rental
ADD COLUMN status VARCHAR;

--Update the newly added status column of the rental table using the case when statement to determine
--if the rental_duration time is greater than the difference between return date and rental date (status is early)
--if the rental_duration time is less than the difference between return date and rental date (status is late)
--if the rental_duration time is equal to the difference between return date and rental date (status is on time)
--and then the else is for those rentals not returned yet (return date is null)
--The film table holds rental_duration and rental holds the return_date and rental_date fields. Used the inventory TABLE
--to go between film and rental
UPDATE rental
SET status = 
	CASE WHEN rental_duration > (return_date::date - rental_date::date) THEN 'Early'
	 WHEN rental_duration < (return_date::date - rental_date::date) THEN 'Late'
	 WHEN rental_duration = (return_date::date - rental_date::date) THEN 'On-Time'
	 ELSE 'Not returned yet' END
FROM film f
	where film_id in 
	(select i.film_id from inventory i
	where i.inventory_id = rental.inventory_id);
	 
--2.	Show the total payment amounts for people who live in Kansas City or Saint Louis. 
-- Added the total amount (sum of amount from payment table) for customers who live in Kansas City or Saint Louis
-- inner joins between payment and customer, customer and address, address and city to get to the city field
SELECT sum(amount) AS pay_amount
	FROM payment p
	INNER JOIN customer c
	ON p.customer_id = c.customer_id
		INNER JOIN address a
		ON c.address_id = a.address_id
			INNER JOIN city c2
			ON a.city_id = c2.city_id
			AND (city = 'Kansas City' OR city = 'Saint Louis');
			
--3.	How many films are in each category? Why do you think there is a table for category and a table for film category?
-- Counted the number of film ids on the film_category table, inner join between category and film_category to get
-- category name
-- There is a table for category and a table for film category because there are multiple films per category

SELECT COUNT(film_id) films_per_cat, cat.name
FROM category cat
	INNER JOIN film_category fc
	ON cat.category_id = fc.category_id
GROUP BY cat.name;

--4.	Show a roster for the staff that includes their email, address, city, and country (not ids)
-- Selected name and email from staff, inner joined to address using address_id to get address and city_id to inner join
-- with city, then inner joined to country using country_id
SELECT CONCAT(first_name, ' ', last_name) name, 
	s.email,
	a.address,
	c.city,
	ct.country
FROM staff s
	INNER JOIN address a
	ON s.address_id = a.address_id
		INNER JOIN city c
		ON a.city_id = c.city_id
			INNER JOIN country ct
			ON c.country_id = ct.country_id;
			
--5.	Show the film_id, title, and length for the movies that were returned from May 15 to 31, 2005
-- Selecting film_id, title, and length (duration) from the film table, inner joining with inventory, then 
-- rental to find those movies with return dates between May 5th and May 31st of 2005

SELECT f.film_id, 
		title,
		length
FROM film f
	INNER JOIN inventory i
	ON f.film_id = i.film_id
		INNER JOIN rental r
		ON i.inventory_id = r.inventory_id
--using where clause to select those returned from May 15, 2005 to May 31, 2005
	WHERE return_date BETWEEN '2005-5-15' AND '2005-05-31';
	
--6.	Write a subquery to show which movies are rented below the average price for all movies. 
-- From the film table, used a subquery in both the select and where clauses - in the select to show what the 
-- average rental_rate is for all movies and in the where clause to narrow down the movies by checking that 
-- the rental_rate is less than the average.

SELECT film_id, 
		title,
		rental_rate,
		(SELECT ROUND(AVG(rental_rate),2) total_avg FROM film)
FROM film
WHERE rental_rate <
	(SELECT ROUND(AVG(rental_rate),2) total_avg FROM film);
	
--7.	Write a join statement to show which movies are rented below the average price for all movies.
-- Using the film table and cross joining to itself then accessing the having clause
-- to narrow down the selection so only those movies where the rental_rate is less than the average of rental_rate.
SELECT f1.title,
		f1.film_id, 
		f1.rental_rate,
		round(avg(f2.rental_rate),2) as avg_tot
FROM film f1
	CROSS JOIN film f2
GROUP BY f1.title, f1.film_id, f1.rental_rate
HAVING f1.rental_rate < avg(f2.rental_rate);

-- 8.	Perform an explain plan on 6 and 7, and describe what you’re seeing and important ways they differ.
-- #6 (with the subquery) appears to be more efficient/faster than #7. Perhaps it has something to do with the 
-- why I wrote it. #6 ran in 49 msec with 11 rows of output. #7 ran in 200 msec with 10 rows of output. Used the same
-- field selection in both and rounded the AVG. #6 has a WHERE clause, #7 has a HAVING clause where the filter is done.
--#6 Explain
EXPLAIN ANALYZE
SELECT film_id, 
		title,
		rental_rate,
		(SELECT ROUND(AVG(rental_rate),2) total_avg FROM film)
FROM film
WHERE rental_rate <
	(SELECT ROUND(AVG(rental_rate),2) total_avg FROM film);
	
--#7 EXPLAIN
EXPLAIN ANALYZE
SELECT f1.title,
		f1.film_id, 
		f1.rental_rate,
		round(avg(f2.rental_rate),2) as avg_tot
FROM film f1
	CROSS JOIN film f2
GROUP BY f1.title, f1.film_id, f1.rental_rate
HAVING f1.rental_rate < avg(f2.rental_rate);


--9.	With a window function, write a query that shows the film, its duration, and what percentile the duration fits into. 
--This may help https://mode.com/sql-tutorial/sql-window-functions/#rank-and-dense_rank 
-- chose the NTILE window function to determine what percentile the length (which in this case is duration) falls into. 
-- The ORDER BY length determined which column to use for percentiles. OVER designates it as a window function. 
-- Grouped by the length and title then ordered by the percentile descending - all from the film table.
SELECT 	title,
		length duration,
		NTILE(100) OVER 
		(ORDER BY length) percentile
FROM film
GROUP BY length, title
ORDER BY percentile DESC;

--10.	In under 100 words, explain what the difference is between set-based and procedural programming. Be sure to specify which sql and python are. 
--SQL is set based, works on groups of data. Python is procedural and goes line by line. 
-- You can think of it this way - set based code is working with a column, procedural is working with a row, set based
-- is more efficient because you can solve all entities on one pass, where procedural is for one entity at a time

--Bonus:
--Find the relationship that is wrong in the data model. Explain why it’s wrong.
-- Customer to rental relationship appears to be wrong. 
-- It shows that a customer cannot have more than one rental, which does not make sense

