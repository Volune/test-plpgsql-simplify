CREATE OR REPLACE FUNCTION simplify_geometry(geom geometry, tolerance float)
  RETURNS geometry AS
$BODY$ 

declare linestring geometry;
declare dumped_points geometry[];
declare arr_len int;
declare x int;
declare fixed_geom geometry default 'LINESTRING EMPTY';

begin

  --get linestring from original polyon's outer ring
  linestring := st_exteriorring(geom);
  --add a new repeated point after start point 
  linestring := st_addpoint(linestring, st_pointn(linestring,2),2);

  --dump point to array
  dumped_points:=array(select (st_dumppoints(linestring)).geom);
  arr_len:= array_length(dumped_points,1);

  --create new linestring, starting from new start point
  for x in 3..arr_len  loop
     fixed_geom := st_addpoint(fixed_geom, dumped_points[x]);
  end loop;

  --add 1st and 2nd points at end
  fixed_geom := st_addpoint(fixed_geom, dumped_points[1], arr_len-2);
  fixed_geom := st_addpoint(fixed_geom, dumped_points[2], arr_len-1);

  --debug stuff
  raise notice 'new linestring : % ', st_astext(linestring);
  raise notice 'rearranged geom: %', st_astext(fixed_geom);
  --show simplified start point
  raise notice 'simplfied geom : %', st_astext(st_simplify(fixed_geom, $2));

  --return new, simplified polygon
  return st_makepolygon(st_simplify(fixed_geom, $2));

 end
$BODY$  LANGUAGE plpgsql VOLATILE