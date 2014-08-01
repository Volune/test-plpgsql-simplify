CREATE OR REPLACE FUNCTION simplify_geometry(geom geometry, tolerance float)
  RETURNS geometry AS
$BODY$

declare linestring geometry;

begin

  --get linestring from original polyon's outer ring
  linestring := st_exteriorring(geom);
  --add a new repeated point after start point
  linestring := st_addpoint(linestring, st_pointn(linestring, ST_NPoints(linestring)-1), 0);
  linestring := st_simplify(linestring, $2);
  linestring := st_removepoint(linestring, 0);
  linestring := st_removepoint(linestring, ST_NPoints(linestring)-1);
  linestring := st_addpoint(linestring, ST_StartPoint(linestring));

  return st_makepolygon(linestring);
end
$BODY$  LANGUAGE plpgsql IMMUTABLE