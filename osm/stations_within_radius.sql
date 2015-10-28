CREATE TEMPORARY TABLE grid_station_distance AS
(SELECT cell_id,
        ST_DISTANCE(grid.center, ST_TRANSFORM(stop.geom, 32633))::int AS distance,
        stop.stop_id,
        stop.stop_name
 FROM berlin_grid AS grid, vbb_stops AS stop
 WHERE ST_DISTANCE(grid.center, ST_TRANSFORM(stop.geom, 32633)) < 2000);


\COPY grid_station_distance TO 'stations_within_radius.csv' DELIMITER ',' CSV HEADER