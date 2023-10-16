-- Task 1: Which staff members made the highest revenue for each store and deserve a bonus for the year 2017?

-- Solution 1

WITH revenue_per_staff AS (
    SELECT
        s.store_id,
        CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
        SUM(p.amount) AS total_revenue
    FROM payment p
             JOIN staff s ON p.staff_id = s.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY s.store_id, s.staff_id
)
SELECT
    staff_name,
    store_id,
    total_revenue
FROM revenue_per_staff
WHERE total_revenue = (
    SELECT MAX(total_revenue)
    FROM revenue_per_staff
    WHERE store_id = revenue_per_staff.store_id
)
ORDER BY total_revenue DESC;

-- Solution 2 

WITH revenue_per_store AS (
    SELECT
        s.store_id,
        SUM(p.amount) AS total_revenue
    FROM payment p
             JOIN staff s ON p.staff_id = s.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY s.store_id
)
SELECT
    revenue_per_store.store_id,
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
    revenue_per_store.total_revenue
FROM revenue_per_store
JOIN staff s ON s.store_id = revenue_per_store.store_id
WHERE total_revenue = (
    SELECT MAX(total_revenue)
    FROM revenue_per_store
)
ORDER BY total_revenue DESC;

-- Task 2: Which five movies were rented more than the others, and what is the expected age of the audience for these movies?

-- Solution 1

WITH ranked_films AS (
    SELECT
        f.title AS film_title,
        COUNT(*) AS rental_count,
        f.rating AS movie_rating,
        CASE f.rating
            WHEN 'G' THEN 'Suitable for all ages'
            WHEN 'PG' THEN 'around 7 years and older'
            WHEN 'PG-13' THEN 'around 13 years and older'
            WHEN 'R' THEN '17 or 18 and older'
            WHEN 'NC-17' THEN '18 and older'
            END AS expected_age,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
    FROM film f
             JOIN inventory i ON f.film_id = i.film_id
             JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id
)
SELECT film_title, rental_count, expected_age
FROM ranked_films
WHERE rn <= 5
ORDER BY rental_count DESC;

-- Solution 2 

WITH ranked_films AS (
    SELECT
        f.title AS film_title,
        COUNT(*) AS rental_count,
        f.rating AS movie_rating,
        CASE f.rating
            WHEN 'G' THEN 'Suitable for all ages'
            WHEN 'PG' THEN 'around 7 years and older'
            WHEN 'PG-13' THEN 'around 13 years and older'
            WHEN 'R' THEN '17 or 18 and older'
            WHEN 'NC-17' THEN '18 and older'
            END AS expected_age,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking
    FROM film f
             JOIN inventory i ON f.film_id = i.film_id
             JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id
)
SELECT film_title, rental_count, expected_age
FROM ranked_films
WHERE ranking <= 5
ORDER BY rental_count DESC;

-- Task 3: Which actors/actresses didn't act for a longer period of time than the others?

-- Solution 1
SELECT
    a.first_name,
    a.last_name,
    MAX(f.release_year) - MIN(f.release_year) AS gap
FROM actor a
         JOIN film_actor fa ON a.actor_id = fa.actor_id
         JOIN film f ON fa.film_id = f.film_id
GROUP BY a.actor_id
ORDER BY gap DESC;

-- Solution 2
WITH ActorActingYears AS (
    SELECT
        a.first_name,
        a.last_name,
        f.release_year AS acting_year
    FROM actor a
             LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id
             LEFT JOIN film f ON f.film_id = fa.film_id
)
SELECT
    first_name,
    last_name,
    MAX(acting_year) AS last_acting_year,
    MIN(acting_year) AS first_acting_year,
    MAX(acting_year - previous_year) AS max_gap
FROM (
         SELECT
             aay.first_name,
             aay.last_name,
             aay.acting_year,
             (
                 SELECT MAX(acting_year)
                 FROM ActorActingYears apy
                 WHERE apy.first_name = aay.first_name
                   AND apy.last_name = aay.last_name
                   AND apy.acting_year < aay.acting_year
             ) AS previous_year
         FROM ActorActingYears aay
     ) AS ActorPreviousYear
GROUP BY first_name, last_name
ORDER BY max_gap DESC;