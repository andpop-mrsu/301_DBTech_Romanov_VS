import csv

counts = {}

with open("ratings.csv", "r", encoding="utf-8") as file:
    reader = csv.DictReader(file)

    for row in reader:
        user_id = int(row["userId"])
        counts[user_id] = counts.get(user_id, 0) + 1

min_id = min(counts)
max_id = max(counts)

print(min_id, counts[min_id])
print(max_id, counts[max_id])
