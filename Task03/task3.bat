#!/bin/bash
chcp 65001


sqlite3 movies_rating.db < db_init.sql


echo "1. Составить список фильмов, имеющих хотя бы одну оценку. Отсортировать по году выпуска и названию. Оставить первые 10 фильмов."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
SELECT DISTINCT m.title, m.year
FROM movies AS m
JOIN ratings AS r ON r.movie_id = m.id
ORDER BY m.year, m.title
LIMIT 10;
"
echo " "


echo "2. Вывести пользователей, фамилии которых начинаются на букву A. Отсортировать по дате регистрации. Оставить первых 5 пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
SELECT id, name, register_date
FROM users
WHERE substr(name, instr(name, ' ') + 1, 1) = 'A'
ORDER BY register_date
LIMIT 5;
"
echo " "


echo "3. Вывести эксперта, фильм, год выпуска, оценку и дату оценки. Отсортировать по имени эксперта, названию фильма и оценке. Оставить первые 50 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
SELECT
    u.name AS expert,
    m.title AS movie,
    m.year,
    r.rating,
    date(r.timestamp, 'unixepoch') AS rating_date
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
JOIN movies AS m ON m.id = r.movie_id
ORDER BY u.name, m.title, r.rating
LIMIT 50;
"
echo " "


echo "4. Вывести фильмы и присвоенные пользователями теги. Отсортировать по году, названию фильма и тегу. Оставить первые 40 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
SELECT m.title, m.year, t.tag
FROM tags AS t
JOIN movies AS m ON m.id = t.movie_id
ORDER BY m.year, m.title, t.tag
LIMIT 40;
"
echo " "


echo "5. Вывести все фильмы последнего года выпуска, имеющегося в базе данных."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
SELECT title, year
FROM movies
WHERE year = (SELECT MAX(year) FROM movies)
ORDER BY title;
"
echo " "


echo "6. Найти драмы после 2005 года, получившие от женщин оценки не ниже 4.5. Вывести название, год и количество таких оценок."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
SELECT
    m.title,
    m.year,
    COUNT(*) AS high_ratings
FROM movies AS m
JOIN ratings AS r ON r.movie_id = m.id
JOIN users AS u ON u.id = r.user_id
WHERE m.year > 2005
    AND m.genres LIKE '%Drama%'
    AND u.gender = 'female'
    AND r.rating >= 4.5
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title;
"
echo " "


echo "7. Вывести количество регистраций по годам и определить годы с максимальным и минимальным количеством регистраций."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
WITH yearly AS (
    SELECT
        strftime('%Y', register_date) AS year,
        COUNT(*) AS registrations
    FROM users
    GROUP BY strftime('%Y', register_date)
),
limits AS (
    SELECT
        MAX(registrations) AS max_count,
        MIN(registrations) AS min_count
    FROM yearly
)
SELECT
    yearly.year,
    yearly.registrations,
    CASE
        WHEN yearly.registrations = limits.max_count THEN 'Максимум'
        WHEN yearly.registrations = limits.min_count THEN 'Минимум'
        ELSE ''
    END AS result
FROM yearly
CROSS JOIN limits
ORDER BY yearly.year;
"
echo " "