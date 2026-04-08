CREATE TABLE stations (
    station_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    capacity INT NOT NULL CHECK (capacity >= 0),
    status BOOLEAN DEFAULT true,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE CHECK (created_at >= '2026-01-01')
);

CREATE TABLE bikes (
    bike_id SERIAL PRIMARY KEY,
    station_id INT NOT NULL REFERENCES stations(station_id) ON DELETE RESTRICT,
    model VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('available', 'rented', 'maintenance')),
    purchase_year INT CHECK (purchase_year >= 2020),
    price_per_hour NUMERIC(6,2) NOT NULL CHECK (price_per_hour >= 0),
    UNIQUE (bike_id, station_id) 
);

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE CHECK (registration_date >= '2026-01-01'),
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    bike_id INT NOT NULL REFERENCES bikes(bike_id) ON DELETE RESTRICT,
    station_from INT NOT NULL REFERENCES stations(station_id),
    station_to INT REFERENCES stations(station_id),
    rental_start DATE NOT NULL DEFAULT CURRENT_DATE CHECK (rental_start >= '2026-01-01'),
    rental_end DATE CHECK (rental_end >= rental_start),
    total_cost NUMERIC(8,2) CHECK (total_cost >= 0),
    CONSTRAINT fk_rental_bike_station CHECK (station_from IS NOT NULL)
);

INSERT INTO stations (name, location, capacity, status, created_at)
VALUES 
    ('Central Park', 'Almaty, Central Park', 20, true, '2026-01-15'),
    ('Railway Station', 'Almaty, Railway Station', 15, true, '2026-02-01'),
    ('University Area', 'Almaty, Satpayev St', 25, true, '2026-01-20'),
    ('Airport', 'Almaty International Airport', 10, true, '2026-03-05');

INSERT INTO bikes (station_id, model, status, purchase_year, price_per_hour)
VALUES 
    (1, 'City Cruiser', 'available', 2025, 500.00),
    (1, 'Mountain Pro', 'rented', 2024, 700.00),
    (2, 'Electric Bike', 'available', 2026, 1200.00),
    (3, 'City Cruiser', 'maintenance', 2025, 550.00),
    (4, 'Foldable Mini', 'available', 2026, 800.00);

INSERT INTO users (full_name, email, phone, registration_date, is_active)
VALUES 
    ('Магжан Узаккали', 'magzhan@example.com', '+77001234567', '2026-01-10', true),
    ('Айжан Смагулова', 'aizhan@example.com', '+77009876543', '2026-02-05', true),
    ('Нурлан Каримов', 'nurlan@example.com', NULL, '2026-01-25', true),
    ('Динара Ахметова', 'dinara@example.com', '+77005556677', '2026-03-01', true);

INSERT INTO rentals (user_id, bike_id, station_from, station_to, rental_start, rental_end, total_cost)
VALUES 
    (1, 2, 1, 2, '2026-02-10', '2026-02-10', 3500.00),
    (2, 1, 1, 3, '2026-03-05', '2026-03-05', 1500.00),
    (3, 3, 2, 1, '2026-04-01', NULL, NULL),
    (4, 5, 4, 4, '2026-03-20', '2026-03-20', 2400.00);