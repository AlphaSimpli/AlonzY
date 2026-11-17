-- Active PostGIS dans un schéma dédié.
CREATE SCHEMA IF NOT EXISTS extensions;

CREATE EXTENSION IF NOT EXISTS postgis
WITH SCHEMA extensions;