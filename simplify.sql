CREATE OR REPLACE FUNCTION simplify_geometry(geom geometry, tolerance float)
  RETURNS geometry AS
$BODY$

DECLARE geomType text;
DECLARE simplified geometry;
DECLARE testSegment geometry;
DECLARE simplifiedElements geometry[];
DECLARE simplifiedHoles geometry[];

BEGIN

  geomType := GeometryType(geom);

  IF ST_IsEmpty(geom) THEN
    RETURN geom;
  ELSIF geomType ~ '(MULTI|COLLECTION)' THEN
    simplifiedElements := array(SELECT simplify_geometry((ST_Dump(geom)).geom, tolerance));
    RETURN ST_Collect(simplifiedElements);
  ELSIF geomType = 'LINESTRING' THEN
    simplified := ST_Simplify(geom, tolerance);

    IF ST_IsClosed(simplified) THEN
      testSegment := ST_MakeLine(ST_PointN(simplified, 2), ST_PointN(simplified, ST_NPoints(simplified)-1));
      IF ST_Distance(ST_StartPoint(simplified), testSegment) < tolerance THEN
        simplified := ST_RemovePoint(simplified, 0);
        simplified := ST_RemovePoint(simplified, ST_NPoints(simplified)-1);
        simplified := ST_AddPoint(simplified, ST_StartPoint(simplified));
      END IF;
    END IF;

    RETURN simplified;
  ELSIF geomType = 'POLYGON' THEN
    simplifiedElements := array(SELECT simplify_geometry(ST_ExteriorRing((ST_DumpRings(geom)).geom), tolerance));
    IF simplifiedElements[1] IS NULL OR ST_NPoints(simplifiedElements[1]) < 4 THEN
      RETURN NULL;
    ELSE
      simplifiedHoles := array(
        SELECT el
        FROM (SELECT unnest(simplifiedElements[2:array_length(simplifiedElements,1)]) AS el) AS holes
        WHERE el IS NOT NULL AND ST_NPoints(el) >= 4
      );
      RETURN ST_MakePolygon(simplifiedElements[1], simplifiedHoles);
    END IF;
  ELSE
    RETURN ST_Simplify(geom, tolerance);
  END IF;

END
$BODY$  LANGUAGE plpgsql IMMUTABLE