from itertools import permutations, combinations
import random
from time import sleep

import pandas as pd

import vbb

stops = pd.read_csv("../vbb_raw/stops_berlin.csv", sep=",")
stops = stops[["stop_id","stop_name"]]
stops = [tuple(stop) for stop in stops.values]

pairs = list(permutations(stops, 2))

# for now, only keep the ones that end at Alexanderplatz
alex = 9100003
pairs = [pair for pair in pairs if pair[1][0]==alex]

# query vbb api for average trip duration
random.shuffle(pairs)

durations = []
for i, ((origin_id, origin_name), (destination_id, destination_name)) in enumerate(pairs):
    print (i)
    try:
        duration = vbb.trip_duration(origin_id, destination_id)
        durations.append((origin_id, origin_name, destination_id, destination_name, duration))
    except:
        print (origin_id, origin_name, destination_id, destination_name)
    sleep(random.randint(10, 800) / 1000.0)

durations = pd.DataFrame(durations,
                         columns=["origin_id", "origin_name", "destination_id", "destination_name", "duration"])
durations = durations.sort("duration")
durations.to_csv("durations.csv", index=False)
