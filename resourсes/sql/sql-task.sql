
-- 1. Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT aircrafts_data.model  AS модель_самолёта,
       seats.fare_conditions AS класс_обслуживания,
       COUNT(seats.seat_no)  AS количество_мест
FROM aircrafts_data
         INNER JOIN seats ON aircrafts_data.aircraft_code = seats.aircraft_code
GROUP BY aircrafts_data.model,
         seats.fare_conditions
ORDER BY aircrafts_data.model;

-- 2. Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT aircrafts_data.model AS модель_самолёта,
       COUNT(seats.seat_no) AS количество_мест
FROM aircrafts_data
         INNER JOIN seats ON aircrafts_data.aircraft_code = seats.aircraft_code
GROUP BY aircrafts_data.model
ORDER BY количество_мест DESC
LIMIT 3;

-- 3. Найти все рейсы, которые задерживались более 2 часов
SELECT flight_no                              AS номер_рейса,
       model                                  AS модель_самолёта,
       scheduled_arrival                      AS запланированное_прибытие,
       actual_arrival                         AS фактическое_время_прибытия,
       AGE(actual_arrival, scheduled_arrival) AS разница_во_времени
FROM flights
         INNER JOIN bookings.aircrafts_data ad on ad.aircraft_code = flights.aircraft_code
WHERE AGE(actual_arrival, scheduled_arrival) > INTERVAL '2 hours';

-- 4. Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
SELECT tickets.passenger_name AS имя_пассажира,
       tickets.contact_data   AS контактные_данные
FROM tickets
         INNER JOIN bookings.ticket_flights tf on tickets.ticket_no = tf.ticket_no
WHERE tf.fare_conditions = 'Business'
ORDER BY tf.ticket_no DESC
LIMIT 10;

-- 5. Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
SELECT f.flight_id           AS id_рейса,
       f.flight_no           AS номер_рейса,
       f.scheduled_departure AS запланированное_отправление,
       f.scheduled_arrival   AS запланированное_прибытие
FROM flights f
WHERE NOT EXISTS (SELECT 1
                  FROM ticket_flights tf
                  WHERE tf.flight_id = f.flight_id
                    AND tf.fare_conditions = 'Business');

-- 6. Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
SELECT DISTINCT ad.airport_name AS имя_аэропорта,
                ad.city         AS город
FROM flights f
         JOIN
     airports_data ad ON f.departure_airport = ad.airport_code
WHERE f.status = 'Delayed';

-- 7. Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
SELECT ad.airport_name    AS имя_аэропорта,
       COUNT(f.flight_id) AS количество_рейсов
FROM flights f
         JOIN
     airports_data ad ON f.departure_airport = ad.airport_code
GROUP BY ad.airport_name
ORDER BY количество_рейсов DESC;

-- 8. Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
SELECT flight_id         AS id_рейса,
       flight_no         AS номер_рейса,
       scheduled_arrival AS запланированное_прибытие,
       actual_arrival    AS фактическое_прибытие
FROM flights
WHERE actual_arrival IS NOT NULL
  AND actual_arrival <> scheduled_arrival;

-- 9. Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
SELECT ad.aircraft_code  AS код_самолета,
       ad.model          AS модель_самолёта,
       s.seat_no         AS номер_места,
       s.fare_conditions AS класс_обслуживания
FROM aircrafts_data ad
         JOIN
     seats s ON ad.aircraft_code = s.aircraft_code
WHERE ad.model ->> 'en' = 'Airbus A321-200'
  AND s.fare_conditions != 'Economy'
ORDER BY s.seat_no;

-- 10. Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT ad.city         AS город,
       ad.airport_code AS код_аэропорта,
       ad.airport_name AS имя_аэропорта
FROM airports_data ad
WHERE ad.city IN (SELECT city
                  FROM airports_data
                  GROUP BY city
                  HAVING COUNT(airport_code) > 1)
ORDER BY ad.city, ad.airport_code;

-- 11. Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
WITH total_booking_amounts AS (SELECT t.passenger_id,
                                      SUM(b.total_amount) AS Общая_сумма
                               FROM tickets t
                                        JOIN
                                    bookings b ON t.book_ref = b.book_ref
                               GROUP BY t.passenger_id),
     average_booking_amount AS (SELECT AVG(total_amount) AS средняя_сумма
                                FROM bookings)
SELECT tba.passenger_id,
       tba.Общая_сумма
FROM total_booking_amounts tba,
     average_booking_amount aba
WHERE tba.Общая_сумма > aba.средняя_сумма;

-- 12. Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT f.flight_id           AS id_рейса,
       f.flight_no           AS номер_рейса,
       f.scheduled_departure AS запланированное_отправление,
       f.scheduled_arrival   AS запланированное_прибытие,
       f.status              AS статус_рейсов
FROM flights f
         JOIN
     airports_data ad_departure ON f.departure_airport = ad_departure.airport_code
         JOIN
     airports_data ad_arrival ON f.arrival_airport = ad_arrival.airport_code
WHERE ad_departure.city ->> 'en' = 'Yekaterinburg'
  AND ad_arrival.city ->> 'en' = 'Moscow'
  AND f.scheduled_departure < NOW()
  AND f.status IN ('Scheduled', 'On Time', 'Delayed')
ORDER BY f.scheduled_departure
LIMIT 1;

-- 13. Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
SELECT 'Cheapest Ticket' AS ticket_type,
       ticket_no,
       amount
FROM ticket_flights
WHERE amount = (SELECT MIN(amount) FROM ticket_flights)
UNION ALL
SELECT 'Most Expensive Ticket' AS ticket_type,
       ticket_no,
       amount
FROM ticket_flights
WHERE amount = (SELECT MAX(amount) FROM ticket_flights);

-- 14. Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
CREATE TABLE Customers
(
    id        SERIAL PRIMARY KEY,
    firstName VARCHAR(50)  NOT NULL,
    lastName  VARCHAR(50)  NOT NULL,
    email     VARCHAR(100) NOT NULL UNIQUE,
    phone     VARCHAR(15)  NOT NULL,
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    CONSTRAINT chk_phone_format CHECK (phone ~* '^\+?[0-9\s\-]{7,15}$')
);

COMMENT ON TABLE Customers IS 'Customer information';
COMMENT ON COLUMN Customers.id IS 'Unique identifier for each customer';
COMMENT ON COLUMN Customers.firstName IS 'Customer first name';
COMMENT ON COLUMN Customers.lastName IS 'Customer last name';
COMMENT ON COLUMN Customers.email IS 'Customer email address';
COMMENT ON COLUMN Customers.phone IS 'Customer phone number';

-- 15. Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE Orders
(
    id         SERIAL PRIMARY KEY,
    customerId INTEGER NOT NULL,
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_customer
        FOREIGN KEY (customerId)
            REFERENCES Customers (id)
            ON DELETE CASCADE
);

COMMENT ON TABLE Orders IS 'Order details';
COMMENT ON COLUMN Orders.id IS 'Unique identifier for each order';
COMMENT ON COLUMN Orders.customerId IS 'Identifier for the customer placing the order';
COMMENT ON COLUMN Orders.quantity IS 'Quantity of items in the order';

-- 16. Написать 5 insert в эти таблицы
-- Вставка данных в таблицу Customers
INSERT INTO Customers (firstName, lastName, email, phone)
VALUES ('John', 'Doe', 'john.doe@example.com', '+1234567890'),
       ('Jane', 'Smith', 'jane.smith@example.com', '+0987654321'),
       ('Alice', 'Johnson', 'alice.johnson@example.com', '+1122334455'),
       ('Bob', 'Brown', 'bob.brown@example.com', '+2233445566'),
       ('Charlie', 'Davis', 'charlie.davis@example.com', '+3344556677');
-- Вставка данных в таблицу Orders
INSERT INTO Orders (customerId, quantity)
VALUES (1, 10),
       (2, 5),
       (3, 7),
       (4, 3),
       (5, 12);

-- 17. Удалить таблицы
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;