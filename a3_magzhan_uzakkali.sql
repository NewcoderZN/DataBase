INSERT INTO film (title, language_id, rental_duration, rental_rate, replacement_cost, last_update, description, fulltext)
SELECT title, language_id, rental_duration, rental_rate, replacement_cost, CURRENT_DATE, description,
       to_tsvector('english', title)
FROM (VALUES
    ('The Matrix', (SELECT language_id FROM language WHERE name = 'English'), 7,  4.99, 19.99, 'A computer hacker learns about the true nature of reality'),
    ('John Wick',  (SELECT language_id FROM language WHERE name = 'English'), 14, 9.99, 24.99, 'An ex-hitman comes out of retirement to track down the gangsters'),
    ('Fight Club', (SELECT language_id FROM language WHERE name = 'English'), 21, 19.99, 29.99, 'An insomniac office worker forms an underground fight club')
) AS d(title, language_id, rental_duration, rental_rate, replacement_cost, description)
WHERE NOT EXISTS (SELECT 1 FROM film f WHERE f.title = d.title);

INSERT INTO actor (first_name, last_name, last_update)
SELECT first_name, last_name, CURRENT_DATE
FROM (VALUES
    ('Keanu',   'Reeves'),
    ('Laurence','Fishburne'),
    ('Carrie',  'Moss'),
    ('Ian',     'McShane'),
    ('Brad',    'Pitt'),
    ('Edward',  'Norton')
) AS a(first_name, last_name)
WHERE NOT EXISTS (
    SELECT 1 FROM actor ac
    WHERE ac.first_name = a.first_name AND ac.last_name = a.last_name
);

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT
    (SELECT actor_id FROM actor WHERE first_name = a AND last_name = b LIMIT 1),
    (SELECT film_id  FROM film  WHERE title = t LIMIT 1),
    CURRENT_DATE
FROM (VALUES
    ('Keanu',    'Reeves',     'The Matrix'),
    ('Laurence', 'Fishburne',  'The Matrix'),
    ('Carrie',   'Moss',       'The Matrix'),
    ('Ian',      'McShane',    'John Wick'),
    ('Brad',     'Pitt',       'Fight Club'),
    ('Edward',   'Norton',     'Fight Club')
) AS v(a, b, t)
ON CONFLICT DO NOTHING;

INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = t LIMIT 1),
    (SELECT store_id FROM store LIMIT 1),
    CURRENT_DATE
FROM (VALUES ('The Matrix'), ('John Wick'), ('Fight Club')) AS v(t)
WHERE NOT EXISTS (
    SELECT 1 FROM inventory i
    WHERE i.film_id = (SELECT film_id FROM film WHERE title = v.t LIMIT 1)
    AND i.store_id  = (SELECT store_id FROM store LIMIT 1)
);

UPDATE customer
SET first_name  = 'Magzhan',
    last_name   = 'Uzakkali',
    email       = 'magzhan.uzakkali@email.com',
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental  r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
    ORDER BY COUNT(DISTINCT r.rental_id) DESC
    LIMIT 1
);

SELECT * FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali');
DELETE FROM payment  WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali');

SELECT * FROM rental  WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali');
DELETE FROM rental   WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali');

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT
    d::date,
    (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = t LIMIT 1) LIMIT 1),
    (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali'),
    d::date + (SELECT rental_duration FROM film WHERE title = t LIMIT 1) * INTERVAL '1 day',
    (SELECT staff_id FROM staff LIMIT 1),
    CURRENT_DATE
FROM (VALUES
    ('2017-01-15', 'The Matrix'),
    ('2017-02-15', 'John Wick'),
    ('2017-03-15', 'Fight Club')
) AS v(d, t)
WHERE NOT EXISTS (
    SELECT 1 FROM rental r
    WHERE r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali')
    AND r.inventory_id  = (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = v.t LIMIT 1) LIMIT 1)
)
RETURNING rental_id, rental_date, return_date;

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT
    (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali'),
    (SELECT staff_id FROM staff LIMIT 1),
    (SELECT rental_id FROM rental
     WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali')
     AND inventory_id  = (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = t LIMIT 1) LIMIT 1)
     LIMIT 1),
    rate,
    pay_date::timestamp
FROM (VALUES
    ('The Matrix',  4.99, '2017-01-15'),
    ('John Wick',   9.99, '2017-02-15'),
    ('Fight Club', 19.99, '2017-03-15')
) AS v(t, rate, pay_date)
WHERE NOT EXISTS (
    SELECT 1 FROM payment p
    WHERE p.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan' AND last_name = 'Uzakkali')
    AND p.payment_date  = v.pay_date::timestamp
);

SELECT 'Films' AS check, title, rental_rate FROM film WHERE title IN ('The Matrix','John Wick','Fight Club');
SELECT 'Actors' AS check, first_name, last_name FROM actor WHERE last_name IN ('Reeves','Fishburne','Moss','McShane','Pitt','Norton');
SELECT 'Customer' AS check, first_name, last_name, email FROM customer WHERE first_name = 'Magzhan';
SELECT 'Rentals' AS check, rental_date, return_date FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan');
SELECT 'Payments' AS check, amount, payment_date FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Magzhan');

COMMIT;
