# Contenu du README de profil GitHub

Le depot `juniorbaw/juniorbaw` **existe deja** (pousse le 2026-08-09). Son
contenu n'a pas ete inspecte ni modifie : ce depot est hors du perimetre de
cette session.

Le contenu ci-dessous est a copier dans le `README.md` de ce depot. Un README a
la racine d'un depot portant exactement le nom d'utilisateur s'affiche en haut
de la page de profil.

---

## A copier dans `juniorbaw/juniorbaw/README.md`

```markdown
# Data Analyst — Retail & Luxury

Je transforme des donnees retail brutes en modeles analytiques testes, ou chaque
chiffre publie est verrouille par un test automatise.

Formation Concepteur Developpeur en IA & Data Analytics (Le Wagon, RNCP niveau 6,
septembre 2026), apres plusieurs annees sur le terrain du retail et du luxe —
dont un flagship parisien.

Je cherche une alternance ou un VIE en analytics engineering, secteur retail ou luxe.

---

## Projets

### [retail-price-gap-analysis](https://github.com/juniorbaw/retail-price-gap-analysis) — Portfolio data

Deux projets. Le principal est un modele dimensionnel dbt sur DuckDB,
reproductible en deux commandes :

- 2 750 transactions, 166 clients, 430 952 USD de CA
- 125 tests dbt a chaque build, dont 6 tests metier singuliers
- Schema en etoile pret pour Power BI, variantes Snowflake documentees

Le projet documente aussi une erreur de grain que j'ai commise : un agregat
client somme au grain transaction, qui multipliait le CA par 17,6. La cause
racine, la correction et le test qui l'empeche de revenir sont ecrits noir sur
blanc dans le [rapport de qualite des donnees](https://github.com/juniorbaw/retail-price-gap-analysis/blob/main/02-fashion-retail-analytics/docs/rapport_qualite_donnees.md).

---

## Stack

**Transformation** dbt (dbt-core, dbt-duckdb, dbt_utils), SQL
**Bases** DuckDB, BigQuery, syntaxe Snowflake
**Langage** Python (pandas)
**BI** Power BI (modele en etoile, DAX), Looker Studio
**Qualite** tests dbt, profilage, documentation de donnees
**Outils** Git, GitHub Actions

---

## Contact

- LinkedIn : https://linkedin.com/in/souleymane-nd
- Email : soujunior94@gmail.com
```

---

## Pourquoi un seul projet en avant

Le brief prevoyait de lier deux projets. Le projet de positionnement prix a des
chiffres qui n'ont pas pu etre revalides (CSV non versionne, API a cle), et deux
de ses chiffres se contredisent entre versions.

Le mettre en avant sur un profil de recrutement avant d'avoir tranche serait
prendre le risque qu'un recruteur pose la question a laquelle on ne peut pas
repondre. Il reste visible dans le portfolio, avec ses limites documentees.

Une fois la collecte rejouee (`make` du projet 01) et les chiffres confirmes,
ajouter une seconde entree sous « Projets ».
