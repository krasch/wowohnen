import pandas as pd

walking_speed = 60./4828     # 3 miles per hour


train_durations = pd.read_csv("../vbb/durations_train.csv")

walk_durations = pd.read_csv("../stations_within_radius.csv")
walk_durations["duration"] = (walk_durations["distance"] * walking_speed).astype(int)

# join: travel to destination from all nearby stations
durations = pd.merge(walk_durations, train_durations, how='inner',
                     left_on="stop_id", right_on="origin_id",
                     suffixes=("_walk", "_train"))

# total trip duration
durations["duration"] = durations["duration_walk"] + durations["duration_train"]
durations = durations[["cell_id", "origin_name", "destination_name", "duration"]]
durations = durations.reset_index(drop=True)

# for each grid point, keep only shortest trip to the destination 7302
def get_shortest_trip(trips):
    trips = trips.sort("duration")
    return trips.iloc[0]

durations = durations.groupby(["cell_id"]).apply(get_shortest_trip)
durations = durations.sort("duration")

durations.to_csv("durations.csv", index=False)