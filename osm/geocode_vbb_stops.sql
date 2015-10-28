-- load vbb stops into database
CREATE TABLE vbb_stops (
  stop_id integer,
  stop_name varchar,
  stop_lat double precision,
  stop_lon double precision,
);

\COPY vbb_stops FROM 'vbb_raw/stops_berlin.csv' DELIMITER ',' CSV HEADER;

-- geocode each stop
ALTER TABLE vbb_stops ADD COLUMN geom geometry(POINT, 900913);
UPDATE vbb_stops SET geom = ST_TRANSFORM(ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326), 900913);
CREATE INDEX idx_stops_geom ON vbb_stops USING GIST(geom);
