-- Création des tables
CREATE TABLE commune (
    code_insee VARCHAR(10) PRIMARY KEY,
    nom_commune VARCHAR(50) NOT NULL,
    code_postale VARCHAR(10) NOT NULL,
    libelle_acheminement VARCHAR(100)
);

CREATE TABLE voie (
    id_fantoir VARCHAR(50) PRIMARY KEY,
    nom_voie TEXT NOT NULL,
    nom_afnor VARCHAR(50),
    source_nom_voie VARCHAR(50),
    code_insee VARCHAR(10) REFERENCES commune(code_insee)
);

CREATE TABLE ancienne_commune (
    code_insee_ancienne_commune VARCHAR(50) PRIMARY KEY,
    nom_ancienne_commune VARCHAR(50)
);

CREATE TABLE lieu_dit (
    nom_ld VARCHAR(50) PRIMARY KEY
);

CREATE TABLE cadastre (
    cad_parcelles TEXT PRIMARY KEY
);

CREATE TABLE adresse (
    id VARCHAR(50) PRIMARY KEY,
    numero INT,
    rep VARCHAR(50),
    x FLOAT4,
    y FLOAT4,
    lon FLOAT4,
    lat FLOAT4,
    type_position VARCHAR(50),
    source_position VARCHAR(50),
    alias TEXT,
    certification_commune INT,
    cad_parcelles TEXT REFERENCES cadastre(cad_parcelles) ON DELETE CASCADE,
    id_fantoir VARCHAR(50) REFERENCES voie(id_fantoir) ON DELETE CASCADE,
    code_insee_ancienne_commune VARCHAR(50) REFERENCES ancienne_commune(code_insee_ancienne_commune) ON DELETE CASCADE,
    nom_ld VARCHAR(50) REFERENCES lieu_dit(nom_ld) ON DELETE CASCADE,
    code_insee VARCHAR(10) REFERENCES commune(code_insee) ON DELETE CASCADE
);

-- Migration des données depuis la table ban

-- Communes
INSERT INTO commune (code_insee, nom_commune, code_postale, libelle_acheminement)
SELECT DISTINCT ON (code_insee) code_insee, nom_commune, code_postal, libelle_acheminement
FROM ban
WHERE code_insee IS NOT NULL
ORDER BY code_insee, nom_commune, code_postal, libelle_acheminement;

-- Anciennes communes
INSERT INTO ancienne_commune (code_insee_ancienne_commune, nom_ancienne_commune)
SELECT DISTINCT code_insee_ancienne_commune, nom_ancienne_commune
FROM ban
WHERE code_insee_ancienne_commune IS NOT NULL;

-- Lieux-dits
INSERT INTO lieu_dit (nom_ld)
SELECT DISTINCT nom_ld
FROM ban
WHERE nom_ld IS NOT NULL;

-- Cadastre
INSERT INTO cadastre (cad_parcelles)
SELECT DISTINCT cad_parcelles
FROM ban
WHERE cad_parcelles IS NOT NULL;

-- Voies
INSERT INTO voie (id_fantoir, nom_voie, nom_afnor, source_nom_voie, code_insee)
SELECT DISTINCT ON (id_fantoir) id_fantoir, nom_voie, nom_afnor, source_nom_voie, code_insee
FROM ban
WHERE id_fantoir IS NOT NULL;

-- Adresses (conversion des champs vides en NULL pour les FK)
INSERT INTO adresse (
    id, numero, rep, x, y, lon, lat, type_position, source_position, alias,
    certification_commune, cad_parcelles, id_fantoir, code_insee_ancienne_commune,
    nom_ld, code_insee
)
SELECT
    id,
    numero,
    rep,
    x,
    y,
    lon,
    lat,
    type_position,
    source_position,
    alias,
    certification_commune,
    cad_parcelles,
    id_fantoir,
    NULLIF(code_insee_ancienne_commune, ''),
    nom_ld,
    code_insee
FROM ban;


--4. Requêtes SQL à produire
--4.1 Requêtes de consultation
--Lister toutes les adresses d’une commune donnée, triées par numéro de voie.
select 
a.numero,
v.nom_voie,
c.nom_commune,
c.code_postale 
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee
WHERE
    c.nom_commune = 'Oullins-Pierre-Bénite'
order by
v.nom_voie,
a.numero asc;

--Compter le nombre d’adresses par commune et par type de voie.
SELECT
    c.nom_commune,
    v.nom_voie,
    COUNT(a.id) AS nb_adresses
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee
GROUP BY
    c.nom_commune,
    v.nom_voie
ORDER BY
    c.nom_commune,
    v.nom_voie;

-- Lister toutes les communes distinctes présentes dans le fichier.
SELECT DISTINCT
    c.nom_commune,
    c.code_insee,
    c.code_postale
FROM
    commune c
ORDER BY
    c.nom_commune;

-- Rechercher toutes les adresses contenant un mot-clé dans le nom de voie.
SELECT
    a.numero,
    v.nom_voie,
    c.nom_commune
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee
WHERE
    v.nom_voie ILIKE '%impasse%'
ORDER BY
    c.nom_commune,
    v.nom_voie, 
    a.numero;

-- Trouver toutes les adresses où le code postal ne correspond pas à la commune.
SELECT
    a.numero,
    v.nom_voie,
    c.nom_commune,
    c.code_postale
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee
WHERE
    c.code_postale NOT IN (
        SELECT DISTINCT code_postale
        FROM commune c2
        WHERE c2.code_insee = c.code_insee
    )
ORDER BY
    c.nom_commune,
    v.nom_voie, 
    a.numero;


--4.2 Requêtes d’insertion / mise à jour / suppression
--Ajouter une nouvelle adresse complète dans les tables finales.
INSERT INTO commune (code_insee, nom_commune, code_postale, libelle_acheminement)
VALUES ('01234', 'Groland', '12345', 'GROLAND')
ON CONFLICT (code_insee) DO NOTHING;

INSERT INTO voie (id_fantoir, nom_voie, nom_afnor, source_nom_voie, code_insee)
VALUES ('FANTOIR123', 'Rue de la Joie', 'RUE DE LA JOIE', 'groland', '01234')
ON CONFLICT (id_fantoir) DO NOTHING;

INSERT INTO lieu_dit (nom_ld)
VALUES ('Le Village')
ON CONFLICT (nom_ld) DO NOTHING;

INSERT INTO cadastre (cad_parcelles)
VALUES ('CAD123')
ON CONFLICT (cad_parcelles) DO NOTHING;

INSERT INTO ancienne_commune (code_insee_ancienne_commune, nom_ancienne_commune)
VALUES ('09999', 'AncienGroland')
ON CONFLICT (code_insee_ancienne_commune) DO NOTHING;


INSERT INTO adresse (
    id, numero, rep, x, y, lon, lat, type_position, source_position, alias,
    certification_commune, cad_parcelles, id_fantoir, code_insee_ancienne_commune,
    nom_ld, code_insee
) VALUES (
    'ADDR001', 1, NULL, 100.0, 200.0, 4.123, 45.678, 'entrée', 'groland', NULL,
    1, 'CAD123', 'FANTOIR123', '09999', 'Le Village', '01234'
);

-- Mettre à jour le nom d’une voie pour une adresse spécifique.
UPDATE voie
SET nom_voie = 'Avenue de la Joie', nom_afnor = 'AVENUE DE LA JOIE'
WHERE id_fantoir = (
    SELECT id_fantoir
    FROM adresse
    WHERE id = 'ADDR001'
);  

--Supprimer toutes les adresses avec un champ manquant critique (ex : numéro de voie vide).
DELETE FROM adresse
WHERE id_fantoir IS NULL OR id_fantoir = '';


--4.3 Détection de problèmes et qualité des données
--Identifier doublons exacts (mêmes numéro + nom de voie + code postal + commune).
SELECT
    a.numero,
    v.nom_voie,
    c.nom_commune,
    c.code_postale,
    COUNT(*) AS nb_occurrences
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee
GROUP BY
    a.numero,
    v.nom_voie,
    c.nom_commune,     
    c.code_postale
HAVING
    COUNT(*) >= 2;

--Identifier les adresses incohérentes, par exemple coordonnées GPS absentes ou en dehors du département.
SELECT
    a.id,
    a.numero,
    v.nom_voie,
    c.nom_commune,
    a.lon,
    a.lat
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee
WHERE
    a.lon IS NULL OR a.lat IS NULL
    OR a.lon < -5.0 OR a.lon > 10.0
    OR a.lat < 41.0 OR a.lat > 51.0;

-- Lister les codes postaux avec plus de 10 000 adresses pour détecter les anomalies volumétriques.
SELECT
    c.code_postale,
    COUNT(a.id) AS nb_adresses
FROM    
    adresse a
    JOIN commune c ON a.code_insee = c.code_insee
GROUP BY
    c.code_postale
HAVING
    COUNT(a.id) > 10000
ORDER BY
    nb_adresses DESC;   


--4.4 Requêtes d’agrégation et analyse
--Nombre moyen d’adresses par commune et par type de voie.
SELECT
    c.nom_commune,
    v.nom_voie,
    COUNT(a.id) AS nb_adresses
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee
GROUP BY
    c.nom_commune,
    v.nom_voie
ORDER BY
    c.nom_commune,
    v.nom_voie;

-- Top 10 des communes avec le plus d’adresses.
SELECT
    c.nom_commune,
    COUNT(a.id) AS nb_adresses
FROM
    adresse a
    JOIN commune c ON a.code_insee = c.code_insee
GROUP BY
    c.nom_commune
ORDER BY    
    nb_adresses DESC
LIMIT 10;

-- Vérifier la complétude des champs essentiels (numéro, voie, code postal, commune).
SELECT
    a.id,
    a.numero,
    a.id_fantoir,
    c.code_postale,
    c.nom_commune
FROM
    adresse a
    JOIN commune c ON a.code_insee = c.code_insee
WHERE
    a.numero IS NULL
    OR a.id_fantoir IS NULL
    OR c.code_postale IS NULL
    OR c.nom_commune IS NULL; 


--4.5 Requêtes avancées
--Créer une procédure stockée pour insérer ou mettre à jour une adresse selon qu’elle existe déjà.
--upsert_adresse = insert or update adresse
--(p_id VARCHAR, ...) : liste des paramètres d’entrée de la fonction (ici, tous les champs d’une adresse).
--RETURNS VOID : la fonction ne retourne pas de valeur.
--AS
--.
--.
--.
--..
--LANGUAGE plpgsql : le code de la fonction est écrit en PL/pgSQL (langage procédural de PostgreSQL).
--BEGIN ... END : délimite le bloc d’instructions de la fonction.
--INSERT INTO ... VALUES (...) : tente d’insérer une nouvelle ligne dans la table adresse avec les valeurs des paramètres.
--ON CONFLICT (id) DO UPDATE SET ... : si une ligne avec le même id existe déjà, met à jour les champs listés avec les nouvelles valeurs (EXCLUDED.colonne = valeur passée).
--EXCLUDED : mot-clé qui désigne les valeurs proposées à l’insertion lors d’un conflit (ici, les nouveaux paramètres).
CREATE OR REPLACE FUNCTION upsert_adresse(
    p_id VARCHAR,
    p_numero INT,
    p_rep VARCHAR,
    p_x FLOAT4,
    p_y FLOAT4,
    p_lon FLOAT4,
    p_lat FLOAT4,
    p_type_position VARCHAR,
    p_source_position VARCHAR,
    p_alias TEXT,
    p_certification_commune INT,
    p_cad_parcelles TEXT,
    p_id_fantoir VARCHAR,
    p_code_insee_ancienne_commune VARCHAR,
    p_nom_ld VARCHAR,
    p_code_insee VARCHAR
) RETURNS VOID AS $$
BEGIN
    INSERT INTO adresse (
        id, numero, rep, x, y, lon, lat, type_position, source_position, alias,
        certification_commune, cad_parcelles, id_fantoir, code_insee_ancienne_commune,
        nom_ld, code_insee
    ) VALUES (  
        p_id, p_numero, p_rep, p_x, p_y, p_lon, p_lat, p_type_position, p_source_position, p_alias,
        p_certification_commune, p_cad_parcelles, p_id_fantoir, p_code_insee_ancienne_commune,
        p_nom_ld, p_code_insee
    )
    ON CONFLICT (id) DO UPDATE SET
         numero = EXCLUDED.numero,
         x = EXCLUDED.x,
         rep = EXCLUDED.rep,
         y = EXCLUDED.y,
         lon = EXCLUDED.lon,
         lat = EXCLUDED.lat,
         type_position = EXCLUDED.type_position,
         source_position = EXCLUDED.source_position,
         alias = EXCLUDED.alias,
         certification_commune = EXCLUDED.certification_commune,
         cad_parcelles = EXCLUDED.cad_parcelles,
         id_fantoir = EXCLUDED.id_fantoir,
         code_insee_ancienne_commune = EXCLUDED.code_insee_ancienne_commune,
         nom_ld = EXCLUDED.nom_ld,
         code_insee = EXCLUDED.code_insee;
END;
$$ LANGUAGE plpgsql;


--Créer un trigger qui vérifie, avant insertion, que les coordonnées GPS sont valides et que le code postal correspond à la commune.
CREATE OR REPLACE FUNCTION validate_adresse()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que les coordonnées GPS sont valides (non nulles et dans des plages raisonnables)
    IF NEW.lon IS NULL OR NEW.lat IS NULL OR
       NEW.lon < -5.0 OR NEW.lon > 10.0 OR
       NEW.lat < 41.0 OR NEW.lat > 51.0 THEN
        RAISE EXCEPTION 'Coordonnées GPS invalides pour l''adresse ID %', NEW.id;
    END IF;

    -- Vérifier que le code postal correspond à la commune
    IF NOT EXISTS (
        SELECT 1 FROM commune
        WHERE code_insee = NEW.code_insee
          AND code_postale = NEW.code_postale
    ) THEN
        RAISE EXCEPTION 'Code postal % non cohérent avec la commune pour l''adresse ID %', NEW.code_postale, NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger sur la table adresse
DROP TRIGGER IF EXISTS trig_validate_adresse ON adresse;
CREATE TRIGGER trig_validate_adresse
BEFORE INSERT OR UPDATE ON adresse
FOR EACH ROW EXECUTE FUNCTION validate_adresse();

-- Ajouter automatiquement une date de création / mise à jour à chaque modification via trigger.
-- Ajouter les colonnes si besoin
ALTER TABLE adresse
ADD COLUMN IF NOT EXISTS date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Fonction de trigger pour mettre à jour la date_modification
CREATE OR REPLACE FUNCTION update_date_modification()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger
DROP TRIGGER IF EXISTS trig_update_date_modification ON adresse;
CREATE TRIGGER trig_update_date_modification
BEFORE UPDATE ON adresse
FOR EACH ROW
EXECUTE FUNCTION update_date_modification();


--5. Optimisation et analyse
--Créer des index sur les champs les plus sollicités.
-- Index sur le code_insee dans la table adresse pour accélérer les requêtes par commune
CREATE INDEX IF NOT EXISTS idx_adresse_code_insee ON adresse(code_insee);

-- Index sur id_fantoir dans la table adresse pour accélérer les requêtes par voie
CREATE INDEX IF NOT EXISTS idx_adresse_id_fantoir ON adresse(id_fantoir);

-- Index sur code_postale dans la table commune pour accélérer les recherches par code postal
CREATE INDEX IF NOT EXISTS idx_commune_code_postale ON commune(code_postale);

-- Index sur nom_voie dans la table voie pour accélérer les recherches par nom de voie
CREATE INDEX IF NOT EXISTS idx_voie_nom_voie ON voie(nom_voie);

-- Comparer les temps d’exécution avant et après indexation.
-- Avant indexation
EXPLAIN ANALYZE
SELECT
    a.numero,
    v.nom_voie,
    c.nom_commune
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee; 
--QUERY PLAN                                                                                                                   |
-----------------------------------------------------------------------------------------------------------------------------+
--Hash Join  (cost=887.57..16971.32 rows=350646 width=37) (actual time=4.455..130.738 rows=350646 loops=1)                     |
--  Hash Cond: ((a.code_insee)::text = (c.code_insee)::text)                                                                   |
--  ->  Hash Join  (cost=878.41..16027.47 rows=350646 width=29) (actual time=4.383..95.499 rows=350646 loops=1)                |
--        Hash Cond: ((a.id_fantoir)::text = (v.id_fantoir)::text)                                                             |
--        ->  Seq Scan on adresse a  (cost=0.00..14228.46 rows=350646 width=20) (actual time=0.006..29.520 rows=350646 loops=1)|
--        ->  Hash  (cost=558.18..558.18 rows=25618 width=29) (actual time=4.344..4.346 rows=25618 loops=1)                    |
--              Buckets: 32768  Batches: 1  Memory Usage: 1822kB                                                               |
--              ->  Seq Scan on voie v  (cost=0.00..558.18 rows=25618 width=29) (actual time=0.002..1.558 rows=25618 loops=1)  |
--  ->  Hash  (cost=5.74..5.74 rows=274 width=20) (actual time=0.054..0.057 rows=274 loops=1)                                  |
--        Buckets: 1024  Batches: 1  Memory Usage: 22kB                                                                        |
--        ->  Seq Scan on commune c  (cost=0.00..5.74 rows=274 width=20) (actual time=0.007..0.025 rows=274 loops=1)           |
Planning Time: 0.288 ms                                                                                                      |
Execution Time: 137.524 ms                                                                                                   |       
-----------------------------------------------------------------------------------------------------------------------------+
-- Après indexation
EXPLAIN ANALYZE
SELECT
    a.numero,
    v.nom_voie,
    c.nom_commune
FROM
    adresse a
    JOIN voie v ON a.id_fantoir = v.id_fantoir
    JOIN commune c ON a.code_insee = c.code_insee;   
QUERY PLAN                                                                                                                   |
-----------------------------------------------------------------------------------------------------------------------------+
--Hash Join  (cost=887.57..16971.32 rows=350646 width=37) (actual time=3.661..110.316 rows=350646 loops=1)                     |
--  Hash Cond: ((a.code_insee)::text = (c.code_insee)::text)                                                                   |
--  ->  Hash Join  (cost=878.41..16027.47 rows=350646 width=29) (actual time=3.620..80.138 rows=350646 loops=1)                |
--        Hash Cond: ((a.id_fantoir)::text = (v.id_fantoir)::text)                                                             |
--        ->  Seq Scan on adresse a  (cost=0.00..14228.46 rows=350646 width=20) (actual time=0.004..24.750 rows=350646 loops=1)|
--        ->  Hash  (cost=558.18..558.18 rows=25618 width=29) (actual time=3.597..3.597 rows=25618 loops=1)                    |
--              Buckets: 32768  Batches: 1  Memory Usage: 1822kB                                                               |
--              ->  Seq Scan on voie v  (cost=0.00..558.18 rows=25618 width=29) (actual time=0.002..1.201 rows=25618 loops=1)  |
--  ->  Hash  (cost=5.74..5.74 rows=274 width=20) (actual time=0.037..0.037 rows=274 loops=1)                                  |
--        Buckets: 1024  Batches: 1  Memory Usage: 22kB                                                                        |
--        ->  Seq Scan on commune c  (cost=0.00..5.74 rows=274 width=20) (actual time=0.004..0.016 rows=274 loops=1)           |
Planning Time: 0.210 ms                                                                                                      |
Execution Time: 116.145 ms       

--Optionnel : tester l’impact de la normalisation sur la taille et la lisibilité de la base.
-- Taille de la table source
SELECT pg_size_pretty(pg_total_relation_size('ban')) AS taille_ban;
--taille_ban|
------------+
--67 MB     |
--QUERY PLAN                                                                                                          |
----------------------------------------------------------------------------------------------------------------------+
--Gather  (cost=1000.00..11426.78 rows=515 width=41) (actual time=0.254..21.402 rows=715 loops=1)                     |
--  Workers Planned: 2                                                                                                |
--  Workers Launched: 2                                                                                               |
--  ->  Parallel Seq Scan on ban  (cost=0.00..10375.28 rows=215 width=41) (actual time=9.320..15.565 rows=238 loops=3)|
--        Filter: (code_insee = 69003)                                                                                |
--        Rows Removed by Filter: 116644                                                                              |
Planning Time: 0.057 ms                                                                                             |
Execution Time: 21.461 ms                                                                                           |

-- Taille totale des tables normalisées
SELECT
  pg_size_pretty(
    pg_total_relation_size('commune') +
    pg_total_relation_size('voie') +
    pg_total_relation_size('adresse') +
    pg_total_relation_size('ancienne_commune') +
    pg_total_relation_size('lieu_dit') +
    pg_total_relation_size('cadastre')
  ) AS taille_normalisee;
--taille_normalisee|
-------------------+
--144 MB           |
--QUERY PLAN                                                                                                          |
----------------------------------------------------------------------------------------------------------------------+
--Gather  (cost=1000.00..11426.78 rows=515 width=41) (actual time=0.204..14.531 rows=715 loops=1)                     |
--  Workers Planned: 2                                                                                                |
--  Workers Launched: 2                                                                                               |
--  ->  Parallel Seq Scan on ban  (cost=0.00..10375.28 rows=215 width=41) (actual time=6.671..10.795 rows=238 loops=3)|
--        Filter: (code_insee = 69003)                                                                                |
--        Rows Removed by Filter: 116644                                                                              |
Planning Time: 0.049 ms                                                                                             |
Execution Time: 14.565 ms   

--On peut observer que les timings poour la requête normalisée sont inférieurs à ceux de la requête non normalisée, ce qui suggère une amélioration des performances (voir planing Time et Execution Time).
