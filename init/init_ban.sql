CREATE TABLE IF NOT EXISTS ban (
    id VARCHAR,
    id_fantoir VARCHAR,
    numero INT,
    rep VARCHAR,
    nom_voie TEXT,
    code_postal VARCHAR,
    code_insee VARCHAR,
    nom_commune VARCHAR,
    code_insee_ancienne_commune VARCHAR,
    nom_ancienne_commune VARCHAR,
    x FLOAT4,
    y FLOAT4,
    lon FLOAT4,
    lat FLOAT4,
    type_position VARCHAR,
    alias TEXT,
    nom_ld VARCHAR,
    libelle_acheminement VARCHAR,
    nom_afnor VARCHAR,
    source_position VARCHAR,
    source_nom_voie VARCHAR,
    certification_commune INT,
    cad_parcelles TEXT
);

-- Import du CSV dans la table ban, en précisant l'ordre exact des colonnes et en gérant les champs vides comme NULL
COPY ban (
    id, id_fantoir, numero, rep, nom_voie, code_postal, code_insee, nom_commune, code_insee_ancienne_commune, nom_ancienne_commune,
    x, y, lon, lat, type_position, alias, nom_ld, libelle_acheminement, nom_afnor, source_position, source_nom_voie, certification_commune, cad_parcelles
) FROM '/docker-entrypoint-initdb.d/adresses-69.csv' DELIMITER ';' CSV HEADER NULL '';