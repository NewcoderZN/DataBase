CREATE SCHEMA IF NOT EXISTS airline;
SET search_path TO airline;

CREATE TABLE IF NOT EXISTS airlines (
    airline_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    iata_code VARCHAR(3) UNIQUE NOT NULL,
    country VARCHAR(50),
    is_active BOOLEAN DEFAULT true
);
CREATE TABLE IF NOT EXISTS airports (
    airport_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    iata_code VARCHAR(3) UNIQUE NOT NULL,
    city VARCHAR(50) NOT NULL
);
CREATE TABLE IF NOT EXISTS aircraft (
    aircraft_id SERIAL PRIMARY KEY,
    model VARCHAR(50) NOT NULL,
    registration_no VARCHAR(20) UNIQUE NOT NULL,
    seat_capacity INT NOT NULL CHECK (seat_capacity > 0),
    airline_id INT REFERENCES airlines(airline_id)
);
CREATE TABLE IF NOT EXISTS passengers (
    passenger_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    passport_no VARCHAR(20) UNIQUE NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('M', 'F', 'Other')),
    birth_date DATE CHECK (birth_date > '1900-01-01')
);
CREATE TABLE IF NOT EXISTS flights (
    flight_id SERIAL PRIMARY KEY,
    flight_no VARCHAR(10) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    origin_id INT REFERENCES airports(airport_id),
    destination_id INT REFERENCES airports(airport_id),
    aircraft_id INT REFERENCES aircraft(aircraft_id),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);
CREATE TABLE IF NOT EXISTS bookings (
    booking_id SERIAL PRIMARY KEY,
    passenger_id INT REFERENCES passengers(passenger_id),
    flight_id INT REFERENCES flights(flight_id),
    seat_class VARCHAR(20) DEFAULT 'economy' CHECK (seat_class IN ('economy', 'business', 'first')),
    base_price NUMERIC(10,2),
    tax_rate NUMERIC(4,2) DEFAULT 0.10,
    total_price NUMERIC(10,2) GENERATED ALWAYS AS (base_price + base_price * tax_rate) STORED,
    status VARCHAR(20) DEFAULT 'confirmed'
);

-- исправления
ALTER TABLE passengers ADD COLUMN phone VARCHAR(15);
ALTER TABLE passengers ALTER COLUMN phone TYPE VARCHAR(20); -- международные номера длиннее
ALTER TABLE passengers RENAME COLUMN phone TO phone_number;
ALTER TABLE bookings ADD CONSTRAINT chk_status CHECK (status IN ('confirmed', 'cancelled', 'pending'));
ALTER TABLE flights ADD COLUMN notes VARCHAR(200);
ALTER TABLE flights DROP COLUMN notes;

TRUNCATE TABLE bookings CASCADE; TRUNCATE TABLE flights CASCADE; TRUNCATE TABLE aircraft CASCADE;
TRUNCATE TABLE passengers CASCADE; TRUNCATE TABLE airports CASCADE; TRUNCATE TABLE airlines CASCADE;

INSERT INTO airlines (name, iata_code, country) VALUES
('Air Astana','KC','Kazakhstan'),('Turkish Airlines','TK','Turkey'),('Emirates','EK','UAE'),('Lufthansa','LH','Germany');

INSERT INTO airports (name, iata_code, city) VALUES
('Nursultan Nazarbayev International','NQZ','Astana'),('Almaty International','ALA','Almaty'),
('Istanbul Airport','IST','Istanbul'),('Dubai International','DXB','Dubai');

INSERT INTO aircraft (model, registration_no, seat_capacity, airline_id) VALUES
('Boeing 767','UP-B6701',250,(SELECT airline_id FROM airlines WHERE iata_code='KC')),
('Airbus A320','UP-A3201',180,(SELECT airline_id FROM airlines WHERE iata_code='KC')),
('Boeing 777','TC-JJA',350,(SELECT airline_id FROM airlines WHERE iata_code='TK')),
('Airbus A380','A6-EDA',520,(SELECT airline_id FROM airlines WHERE iata_code='EK'));

INSERT INTO passengers (full_name, email, passport_no, gender, birth_date) VALUES
('Aibek Seitkali','aibek@gmail.com','N12345678','M','1990-05-15'),
('Dana Bekova','dana@mail.ru','N87654321','F','1995-11-20'),
('Marat Akhmetov','marat@yandex.kz','N11223344','M','1988-03-10'),
('Aliya Nurova','aliya@gmail.com','N44332211','F','2000-07-25');

INSERT INTO flights (flight_no,departure_time,arrival_time,origin_id,destination_id,aircraft_id,price) VALUES
('KC101','2026-02-01 08:00','2026-02-01 10:30',(SELECT airport_id FROM airports WHERE iata_code='NQZ'),(SELECT airport_id FROM airports WHERE iata_code='ALA'),(SELECT aircraft_id FROM aircraft WHERE registration_no='UP-B6701'),45000),
('KC205','2026-02-05 14:00','2026-02-05 19:00',(SELECT airport_id FROM airports WHERE iata_code='ALA'),(SELECT airport_id FROM airports WHERE iata_code='IST'),(SELECT aircraft_id FROM aircraft WHERE registration_no='UP-A3201'),120000),
('TK880','2026-02-10 22:00','2026-02-11 06:00',(SELECT airport_id FROM airports WHERE iata_code='IST'),(SELECT airport_id FROM airports WHERE iata_code='DXB'),(SELECT aircraft_id FROM aircraft WHERE registration_no='TC-JJA'),95000),
('EK301','2026-03-01 10:00','2026-03-01 15:30',(SELECT airport_id FROM airports WHERE iata_code='DXB'),(SELECT airport_id FROM airports WHERE iata_code='NQZ'),(SELECT aircraft_id FROM aircraft WHERE registration_no='A6-EDA'),180000);

INSERT INTO bookings (passenger_id,flight_id,seat_class,base_price) VALUES
((SELECT passenger_id FROM passengers WHERE email='aibek@gmail.com'),(SELECT flight_id FROM flights WHERE flight_no='KC101'),'economy',45000),
((SELECT passenger_id FROM passengers WHERE email='dana@mail.ru'),(SELECT flight_id FROM flights WHERE flight_no='KC205'),'business',120000),
((SELECT passenger_id FROM passengers WHERE email='marat@yandex.kz'),(SELECT flight_id FROM flights WHERE flight_no='TK880'),'economy',95000),
((SELECT passenger_id FROM passengers WHERE email='aliya@gmail.com'),(SELECT flight_id FROM flights WHERE flight_no='EK301'),'first',180000);
