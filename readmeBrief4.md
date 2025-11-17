# Brief4 — Documentation Complète

## 🛠️ Étapes d’installation

1. **Cloner le projet ou décompresser l’archive**
2. Vérifier la présence des fichiers suivants :
   - `docker-compose.yml`
   - Dossier `init/` contenant :
     - `init_ban.sql` (création + import de la table ban)
     - `schema.sql` (création des tables, migration, requêtes, triggers, etc.)
     - `adresses-69.csv` (données brutes)
3. Lancer la base de données et l’import automatique :
   ```bash
   docker compose up
   ```
4. Se connecter à PostgreSQL (exemple) :
   ```bash
   docker exec -it <nom_du_container> psql -U dev -d projet_db
   ```

## 🧩 Choix de modélisation

- **Modélisation MERISE** :
  - Identification des entités : commune, voie, adresse, ancienne_commune, lieu_dit, cadastre
  - Définition des relations et des clés étrangères(voir PDF)
  - Normalisation pour éviter la redondance et garantir l’intégrité
- **Contraintes et règles de gestion** :
  - Clés primaires et étrangères
  - Contraintes NOT NULL, ON DELETE CASCADE
  - Triggers pour la validation métier et la gestion des dates
- **Justification** :
  - Structure adaptée à la volumétrie et à la qualité des données BAN
  - Optimisation des requêtes par indexation

## 📝 Exemples de requêtes

- Lister toutes les adresses d’une commune donnée, triées par numéro de voie :
  ```sql
  SELECT a.numero, v.nom_voie, c.nom_commune, c.code_postale
  FROM adresse a
  JOIN voie v ON a.id_fantoir = v.id_fantoir
  JOIN commune c ON a.code_insee = c.code_insee
  WHERE c.nom_commune = 'Oullins-Pierre-Bénite'
  ORDER BY v.nom_voie, a.numero ASC;
  ```
- Compter le nombre d’adresses par commune et par type de voie :
  ```sql
  SELECT c.nom_commune, v.nom_voie, COUNT(a.id) AS nb_adresses
  FROM adresse a
  JOIN voie v ON a.id_fantoir = v.id_fantoir
  JOIN commune c ON a.code_insee = c.code_insee
  GROUP BY c.nom_commune, v.nom_voie
  ORDER BY c.nom_commune, v.nom_voie;
  ```
- Rechercher toutes les adresses contenant un mot-clé dans le nom de voie :
  ```sql
  SELECT a.numero, v.nom_voie, c.nom_commune
  FROM adresse a
  JOIN voie v ON a.id_fantoir = v.id_fantoir
  JOIN commune c ON a.code_insee = c.code_insee
  WHERE v.nom_voie ILIKE '%impasse%'
  ORDER BY c.nom_commune, v.nom_voie, a.numero;
  ```
- Détection de doublons :
  ```sql
  SELECT a.numero, v.nom_voie, c.nom_commune, c.code_postale, COUNT(*) AS nb_occurrences
  FROM adresse a
  JOIN voie v ON a.id_fantoir = v.id_fantoir
  JOIN commune c ON a.code_insee = c.code_insee
  GROUP BY a.numero, v.nom_voie, c.nom_commune, c.code_postale
  HAVING COUNT(*) >= 2;
  ```

## 🚀 Observations de performance

- **Indexation** :
  - Index créés sur les champs sollicités (`code_insee`, `id_fantoir`, `code_postale`, `nom_voie`)
  - Amélioration mesurée des temps d’exécution des requêtes (voir EXPLAIN ANALYZE)
- **Normalisation** :
  - Réduction de la redondance, meilleure intégrité
  - Les requêtes sont plus lisibles et performantes
- **Exemple de comparaison de performance** :
  - Avant indexation : Execution Time ≈ 137 ms
  - Après indexation : Execution Time ≈ 116 ms

## 💬 Commentaires et explications du script SQL

```sql
-- Création des tables
-- commune, voie, ancienne_commune, lieu_dit, cadastre, adresse
-- Migration des données depuis la table ban
-- Requêtes de consultation, insertion, suppression, qualité
-- Procédure stockée upsert_adresse
-- Triggers de validation et de gestion des dates
-- Indexation et analyse de performance
-- Voir le fichier schema.sql pour tous les commentaires détaillés sur chaque étape et chaque requête.
```

Tous les commentaires présents dans le fichier `schema.sql` sont conservés et accessibles dans le projet.

---


