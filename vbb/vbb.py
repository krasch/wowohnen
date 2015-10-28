import urllib.request
import urllib.parse
import json
from datetime import datetime
from collections import namedtuple
import numpy as np

import credentials

TripLeg = namedtuple('Leg', ['origin_name', 'origin_time', "destination_name", "destination_time", "product"])

def make_request(endpoint, parameters):
    parameters["accessId"] = credentials.access_id
    parameters["format"] = "json"
    parameters = urllib.parse.urlencode(parameters)
    url = "{base_url}/{endpoint}?{parameters}".format(base_url=credentials.base_url,
                                                      endpoint=endpoint,
                                                      parameters=parameters)
    f = urllib.request.urlopen(url)
    response = f.read().decode()
    response = json.loads(response)
    return response


def pretty_print(json_data):
    print(json.dumps(json_data, sort_keys=True, indent=4, separators=(',', ': ')))


def find_station(station_name):
    pretty_print(make_request(endpoint="location.name",
                                       parameters={"input": station_name}))


def parse_leg(leg):
    make_time = lambda date, time: datetime.strptime("{date} {time}".format(date=date, time=time),
                                                     "%Y-%m-%d %H:%M:%S")
    return TripLeg(origin_name=leg["Origin"]["name"].strip(),
                   origin_time=make_time(leg["Origin"]["date"], leg["Origin"]["time"]),
                   destination_name=leg["Destination"]["name"].strip(),
                   destination_time=make_time(leg["Destination"]["date"], leg["Destination"]["time"]),
                   product=leg.get("Product", {"name": ""})["name"].strip())


def trip_duration(origin, destination):
    def calculation_duration(trip_legs):
        duration = trip_legs[-1].destination_time - trip_legs[0].origin_time
        return duration.seconds / 60.0

    def parse_trip(trip):
        return [parse_leg(leg) for leg in trip["LegList"]['Leg']]

    response = make_request(endpoint="trip", parameters={"originExtId": origin,
                                                         "destExtId": destination,
                                                         "date": "2015-11-02",
                                                         "time": "09:00"})

    trips = [parse_trip(trip) for trip in response["Trip"]]
    #for trip in trips:
    #    for leg in trip:
    #        print(leg)
    durations = [calculation_duration(trip) for trip in trips]
    return int(np.mean(durations))

#find_station("U Oranienburger Tor")