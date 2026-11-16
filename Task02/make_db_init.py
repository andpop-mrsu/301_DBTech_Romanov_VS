import csv
import re


def sql_string(value):
    value = value.replace("'", "''")
    return "'" + value + "'"


with open("dataset/movies.csv", encoding="utf-8") as file:
    movies = list(csv.DictReader(file))

with open("dataset/ratings.csv", encoding="utf-8") as file:
    ratings = list(csv.DictReader(file))

with open("dataset/tags.csv", encoding="utf-8") as file:
    tags = list(csv.DictReader(file))
    
users = []

with open("dataset/users.txt", encoding="utf-8") as file:
    for line in file:
        parts = line.strip().split("|")
        users.append(parts)


with open("db_init.sql", "w", encoding="utf-8") as sql:

    sql.write("BEGIN TRANSACTION;\n\n")

    sql.write("DROP TABLE IF EXISTS movies;\n")
    sql.write("DROP TABLE IF EXISTS ratings;\n")
    sql.write("DROP TABLE IF EXISTS tags;\n")
    sql.write("DROP TABLE IF EXISTS users;\n\n")

    sql.write("""
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER,
    genres TEXT
);

""")

    sql.write("""
CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);

""")

    sql.write("""
CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    tag TEXT,
    timestamp INTEGER
);

""")

    sql.write("""
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);

""")

    for movie in movies:
        match = re.search(r"\((\d{4})\)\s*$", movie["title"])

        if match:
            year = match.group(1)
        else:
            year = "NULL"

        sql.write(
            "INSERT INTO movies (id, title, year, genres) VALUES "
            "("
            + movie["movieId"] + ", "
            + sql_string(movie["title"]) + ", "
            + year + ", "
            + sql_string(movie["genres"])
            + ");\n"
        )

    for i, rating in enumerate(ratings, 1):
        sql.write(
            "INSERT INTO ratings "
            "(id, user_id, movie_id, rating, timestamp) VALUES "
            "("
            + str(i) + ", "
            + rating["userId"] + ", "
            + rating["movieId"] + ", "
            + rating["rating"] + ", "
            + rating["timestamp"]
            + ");\n"
        )

    for i, tag in enumerate(tags, 1):
        sql.write(
            "INSERT INTO tags "
            "(id, user_id, movie_id, tag, timestamp) VALUES "
            "("
            + str(i) + ", "
            + tag["userId"] + ", "
            + tag["movieId"] + ", "
            + sql_string(tag["tag"]) + ", "
            + tag["timestamp"]
            + ");\n"
        )

    for user in users:
        sql.write(
            "INSERT INTO users "
            "(id, name, email, gender, register_date, occupation) VALUES "
            "("
            + user[0] + ", "
            + sql_string(user[1]) + ", "
            + sql_string(user[2]) + ", "
            + sql_string(user[3]) + ", "
            + sql_string(user[4]) + ", "
            + sql_string(user[5])
            + ");\n"
        )

    sql.write("\nCOMMIT;\n")


print("db_init.sql создан")