SELECT ST_AsText(simplify_geometry(ST_GeomFromText($1), 1)) AS "geometry"