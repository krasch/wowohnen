-- size of each grid cell in meters
\set grid_cell_width 100
\set grid_cell_height 100


CREATE OR REPLACE FUNCTION make_berlin_grid(grid_cell_width INT, grid_cell_height INT)
RETURNS TABLE (cell_id INT, cell geometry, center geometry)
AS $$ DECLARE

  corner_south_west geometry;
  corner_south_east geometry;
  corner_north_west geometry;
  corner_north_east geometry;
  num_cells_east_west INT;
  num_cells_north_south INT;

BEGIN

  -- corners of the bounding box
  -- 900913 is SRID of the original data, convert to 32633 to allow calculations in meters
  SELECT ST_TRANSFORM(ST_SetSRID(ST_POINT(ST_XMIN(way),ST_YMIN(way)), 900913), 32633),
         ST_TRANSFORM(ST_SetSRID(ST_POINT(ST_XMAX(way),ST_YMIN(way)), 900913), 32633),
         ST_TRANSFORM(ST_SetSRID(ST_POINT(ST_XMIN(way),ST_YMAX(way)), 900913), 32633),
         ST_TRANSFORM(ST_SetSRID(ST_POINT(ST_XMAX(way),ST_YMAX(way)), 900913), 32633)
         INTO corner_south_west, corner_south_east, corner_north_west, corner_north_east
  FROM "public".planet_osm_polygon
  WHERE admin_level='4' AND name LIKE '%Berlin%';

  -- number of cells needed in each direction
  -- add 10 more to each because the world is not flat (at different latitudes the answer might be different)
   SELECT (ST_DISTANCE(corner_south_east, corner_south_west) / grid_cell_width)::int + 10,
          (ST_DISTANCE(corner_south_east, corner_north_east) / grid_cell_height)::int + 10
          INTO num_cells_east_west, num_cells_north_south;

   -- left borders for the grid cells
   CREATE TEMPORARY TABLE temp_xs
   AS (SELECT i_x,
             ST_X(corner_south_west) + grid_cell_width * i_x AS X
       FROM generate_series(0, num_cells_east_west) AS i_x);

   -- right borders for the grid cells
   CREATE TEMPORARY TABLE temp_ys
   AS (SELECT i_y,
             ST_Y(corner_south_west) + grid_cell_height * i_y AS Y
       FROM generate_series(0, num_cells_north_south) AS i_y);

   -- create the grid
   CREATE TEMPORARY TABLE temp_grid
   AS (SELECT i_y * num_cells_east_west + i_x AS cell_id,
              ST_MakeEnvelope(X, Y, X + grid_cell_width, Y +  grid_cell_width, 32633) AS cell
       FROM temp_xs, temp_ys);

   -- only return those cells that intersect with Berlin  todo
   RETURN QUERY
          SELECT temp_grid.cell_id, temp_grid.cell, ST_Centroid(temp_grid.cell) AS center
          FROM temp_grid, "public".planet_osm_polygon
          WHERE admin_level='4' AND name LIKE '%Berlin%'
          AND ST_INTERSECTS(ST_TRANSFORM(way,32633), temp_grid.cell);

   -- cleaning up
   DROP TABLE temp_xs;
   DROP TABLE temp_ys;
   DROP TABLE temp_grid;
END $$ LANGUAGE plpgsql;

CREATE TABLE berlin_grid
AS (SELECT * FROM make_berlin_grid(:grid_cell_width, :grid_cell_height));

-- ogr2ogr -f GeoJSON grid.json "PG:host=localhost dbname=osm user= password=" -sql "SELECT cell_id, st_transform(cell, 4326) FROM berlin_grid"

-- ogr2ogr -f GeoJSON grid.json "PG:host=localhost dbname=osm user= password=" -sql "SELECT cell_id, center FROM berlin_grid"
