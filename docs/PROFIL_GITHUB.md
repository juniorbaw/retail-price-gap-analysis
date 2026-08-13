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

Deux projets.

**Fashion Retail Analytics** — modele dimensionnel dbt sur DuckDB, reproductible
en deux commandes, sans compte cloud.

- 2 750 transactions, 166 clients, 430 952 USD de CA
- 126 tests dbt a chaque build, dont 7 tests metier singuliers
- Schema en etoile pret pour Power BI, variantes Snowflake documentees
- Insight : les VIP achetent moins souvent que les Fideles (777 contre 794).
  Leurs 51,4 % du CA viennent du panier, pas de la frequence.

**Ecarts de prix, mode et luxe** — collecte API et segmentation de prix sur
119 produits.

- Gradient de remise monotone : 42,3 % sur l'accessible, 36,5 % sur le mid,
  19,9 % sur le luxe. Spearman prix / remise : -0,58.
- Facteur 13,6 entre les prix medians des segments accessible et luxe.

Le portfolio documente aussi une erreur de grain que j'ai commise : un agregat
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

## Note

Les chiffres cites viennent tous des valeurs verifiees et sont reproductibles
depuis le depot pour le projet 02. Pour le projet 01, `produits_clean.csv` n'est
pas encore versionne : le rendre reproductible en lecture est l'action 7 de
`ACTIONS_MANUELLES.md`.
