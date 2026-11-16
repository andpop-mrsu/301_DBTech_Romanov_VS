#!/bin/bash

if command -v chcp >/dev/null 2>&1; then
    chcp 65001 > /dev/null
fi

sqlite3 movies_rating.db < db_init.sql

echo "1. Пары пользователей, оценивших один фильм"
sqlite3 movies_rating.db -box -echo "
SELECT DISTINCT
    u1.name AS user1,
    u2.name AS user2,
    m.title AS movie
FROM ratings r1
JOIN ratings r2
    ON r1.movie_id = r2.movie_id
    AND r1.user_id < r2.user_id
JOIN users u1 ON r1.user_id = u1.id
JOIN users u2 ON r2.user_id = u2.id
JOIN movies m ON r1.movie_id = m.id
ORDER BY m.title, u1.name, u2.name
LIMIT 100;
"

echo "2. Десять самых старых оценок от разных пользователей"
sqlite3 movies_rating.db -box -echo "
WITH ranked_ratings AS (
    SELECT
        id, user_id, movie_id, rating, timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY timestamp, id
        ) AS rn
    FROM ratings
)
SELECT
    m.title,
    u.name,
    r.rating,
    date(r.timestamp, 'unixepoch') AS review_date
FROM ranked_ratings r
JOIN movies m ON r.movie_id = m.id
JOIN users u ON r.user_id = u.id
WHERE r.rn = 1
ORDER BY r.timestamp, r.user_id
LIMIT 10;
"

echo "3. Фильмы с максимальным и минимальным средним рейтингом"
sqlite3 movies_rating.db -box -echo "
WITH movie_ratings AS (
    SELECT movie_id, AVG(rating) AS avg_rating
    FROM ratings
    GROUP BY movie_id
)
SELECT
    m.title,
    m.year,
    mr.avg_rating,
    CASE
        WHEN mr.avg_rating = (SELECT MAX(avg_rating) FROM movie_ratings)
        THEN 'Да'
        ELSE 'Нет'
    END AS 'Рекомендуем'
FROM movie_ratings mr
JOIN movies m ON mr.movie_id = m.id
WHERE mr.avg_rating = (SELECT MAX(avg_rating) FROM movie_ratings)
   OR mr.avg_rating = (SELECT MIN(avg_rating) FROM movie_ratings)
ORDER BY m.year, m.title;
"

echo "4. Количество и средняя оценка мужчин за 2011-2014 годы"
sqlite3 movies_rating.db -box -echo "
SELECT
    COUNT(*) AS ratings_count,
    AVG(r.rating) AS average_rating
FROM ratings r
JOIN users u ON r.user_id = u.id
WHERE u.gender = 'male'
  AND strftime('%Y', r.timestamp, 'unixepoch')
      BETWEEN '2011' AND '2014';
"

echo "5. Средний рейтинг и количество пользователей для каждого фильма"
sqlite3 movies_rating.db -box -echo "
SELECT
    m.title,
    m.year,
    AVG(r.rating) AS avg_rating,
    COUNT(DISTINCT r.user_id) AS users_count
FROM movies m
JOIN ratings r ON m.id = r.movie_id
GROUP BY m.id
ORDER BY m.year, m.title
LIMIT 20;
"

echo "Задание 6. Самый распространенный жанр"
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split(movie_id, rest, genre) AS (
    SELECT id, COALESCE(genres, '') || '|', ''
    FROM movies

    UNION ALL

    SELECT
        movie_id,
        substr(rest, instr(rest, '|') + 1),
        substr(rest, 1, instr(rest, '|') - 1)
    FROM split
    WHERE rest <> ''
)
SELECT
    genre,
    COUNT(DISTINCT movie_id) AS movies_count
FROM split
WHERE genre <> ''
GROUP BY genre
ORDER BY movies_count DESC, genre
LIMIT 1;
"

echo "7. Десять последних зарегистрированных пользователей"
sqlite3 movies_rating.db -box -echo "
SELECT
    substr(name, instr(name, ' ') + 1)
    || ' ' ||
    substr(name, 1, instr(name, ' ') - 1)
    || '|' || register_date AS user_info
FROM users
ORDER BY register_date DESC, id DESC
LIMIT 10;
"

echo "8. Дни недели, на которые приходился день рождения пользователя"
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE years(y) AS (
    SELECT 2006
    UNION ALL
    SELECT y + 1 FROM years
    WHERE y < CAST(strftime('%Y', 'now') AS INTEGER)
)
SELECT
    y || '-01-29' AS birthday,
    CASE strftime('%w', y || '-01-29')
        WHEN '0' THEN 'Воскресенье'
        WHEN '1' THEN 'Понедельник'
        WHEN '2' THEN 'Вторник'
        WHEN '3' THEN 'Среда'
        WHEN '4' THEN 'Четверг'
        WHEN '5' THEN 'Пятница'
        WHEN '6' THEN 'Суббота'
    END AS weekday
FROM years;
"