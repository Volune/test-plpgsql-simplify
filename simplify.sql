CREATE OR REPLACE FUNCTION simplify_geometry(geom geometry, tolerance float)
  RETURNS geometry AS
$BODY$

declare linestring geometry;
declare simplified geometry;
declare testSegment geometry;

begin

  simplified := st_simplify(geom, $2);

  if ST_IsClosed(simplified) then
    linestring := st_exteriorring(simplified);
    testSegment := ST_MakeLine(ST_PointN(linestring, 2), ST_PointN(linestring, ST_NPoints(linestring)-1));
    raise notice 'test point : % ', st_astext(ST_StartPoint(linestring));
    raise notice 'test line : % ', st_astext(testSegment);
    raise notice 'distance : % ', ST_Distance(ST_StartPoint(linestring), testSegment);
    if ST_Distance(ST_StartPoint(linestring), testSegment) < tolerance then
      linestring := st_removepoint(linestring, 0);
      linestring := st_removepoint(linestring, ST_NPoints(linestring)-1);
      linestring := st_addpoint(linestring, ST_StartPoint(linestring));
      return st_makepolygon(linestring);
    end if;
  end if;
  return simplified;

end
$BODY$  LANGUAGE plpgsql IMMUTABLE