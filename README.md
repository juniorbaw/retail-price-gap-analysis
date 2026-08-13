# Portfolio Data Analytics — Souleymane N'DIAYE

[![CI](https://github.com/juniorbaw/retail-price-gap-analysis/actions/workflows/ci.yml/badge.svg)](https://github.com/juniorbaw/retail-price-gap-analysis/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Data Analyst — Retail & Luxe.** SQL, dbt, Python, Power BI.

Deux projets. Dans le premier, chaque chiffre publie est verrouille par un test
automatise qui casse le build s'il devient faux. Dans le second, chaque chiffre
est accompagne de la limite methodologique qui le borne.

---

## [02 — Fashion Retail Analytics](02-fashion-retail-analytics/) · projet principal

**Un modele dimensionnel teste, construit avec dbt sur DuckDB.** Reproductible
en deux commandes, sans compte cloud.

| | |
|---|---|
| Transactions | **2 750** (sur 3 400 lignes source) |
| Clients | **166** |
| Chiffre d'affaires | **430 952 USD** |
| Panier moyen / median | 156,71 / 110,00 USD |
| Tests a chaque build | **126** |

**L'insight** : les clients VIP realisent **moins d'achats** que les Fideles
(777 contre 794). Leur surperformance — 25,3 % des clients pour **51,4 % du
CA** — vient entierement du panier (304,02 contre 110,68 USD), pas de la
frequence. **Le levier est la montee en gamme, pas la relance.**

**Ce que le projet raconte vraiment** : la premiere version publiait un CA de
7,6 M — **17,6 fois trop eleve**, soit exactement le nombre moyen de
transactions par client. Un agregat au grain client avait ete recopie sur chaque
ligne de transaction, puis somme. Le chiffre est parti sur un CV.

Le test `assert_coherence_ca` mesure aujourd'hui le CA a deux grains differents
et exige qu'ils coincident. Sur le pipeline fautif, il aurait renvoye un ecart
de 7 154 629 USD et casse le build.

Cause racine, correction et test : [rapport de qualite des donnees](02-fashion-retail-analytics/docs/rapport_qualite_donnees.md).

[Voir le projet](02-fashion-retail-analytics/) · [catalogue de donnees](02-fashion-retail-analytics/docs/data_catalog.md) · [modele Power BI](02-fashion-retail-analytics/dashboard/POWER_BI.md)

`dbt-core` · `dbt-duckdb` · `DuckDB` · `Parquet` · modele Power BI documente

---

## [01 — Ecarts de prix, marche mode et luxe](01-price-positioning-luxury/)

**Collecte via API et segmentation de prix** sur 119 produits mode et luxe.

| | |
|---|---|
| Produits | **119** (dont 55 avec prix barre, 46 %) |
| Prix median / moyen | 376 / 2 724,5 USD |
| Remise ponderee | **23,3 %** (remise simple : 39,4 %) |
| Spearman prix / remise | **-0,58** |

**L'insight** : le gradient de remise est monotone — **42,3 %** sur
l'accessible, **36,5 %** sur le mid, **19,9 %** sur le luxe. La remise decroit a
chaque palier, sans exception. Le luxe ne se brade pas, il protege son prix.

L'ecart de prix entre segments est un facteur **13,6** sur les medianes : le
marche n'est pas un continuum.

`Python` · `pandas` · `API Channel3` · `Looker Studio`

---

## Stack

**Transformation** dbt-core 1.12, dbt-duckdb, dbt_utils
**Bases** DuckDB, SQL (variantes Snowflake documentees)
**Langage** Python 3.11, pandas
**BI** Power BI (modele en etoile + mesures DAX), Looker Studio
**Qualite** 126 tests dbt, GitHub Actions
**Formats** CSV, Parquet

## Ce que ce depot cherche a montrer

- **Un chiffre publie doit etre teste.** `assert_volumetrie` fige les 2 750 et
  166 cites ici ; `assert_segments_reference` fige la table des segments. Si la
  source ou la methode change, le build echoue au lieu de laisser la
  documentation devenir fausse en silence.
- **Le grain avant tout.** Chaque modele declare son grain en commentaire en
  tete de fichier. Faits et agregats sont separes, et la table de faits ne porte
  aucun agregat client — le fan-out devient structurellement impossible.
- **La reproductibilite se verifie.** DuckDB tourne en local : `make setup &&
  make build`, et un lecteur obtient les memes chiffres.
- **Les limites sont publiees a cote des chiffres**, jamais en annexe. Les
  donnees du projet 02 sont **synthetiques** ; l'echantillon du projet 01 n'est
  pas representatif. Les deux sont dits en tete de projet.

## Reproduire

```bash
git clone https://github.com/juniorbaw/retail-price-gap-analysis.git
cd retail-price-gap-analysis
make setup     # dependances Python + packages dbt
make build     # 1 seed + 8 modeles + 126 tests
make kpi       # affiche les chiffres de reference
```

`make build` echoue si un seul test casse — c'est ce que verifie la CI a chaque
push.

Le projet 01 necessite une cle d'API : voir son
[README](01-price-positioning-luxury/#reproduire-ce-projet).

## Structure

```
.
├── 01-price-positioning-luxury/    collecte API, nettoyage, segmentation
├── 02-fashion-retail-analytics/    projet dbt, schema en etoile, tests
├── .github/workflows/ci.yml        dbt build a chaque push
├── Makefile                        setup, build, test, docs, export, clean
└── requirements.txt                versions epinglees
```

## Contact

- LinkedIn : https://linkedin.com/in/souleymane-nd
- Email : soujunior94@gmail.com
- GitHub : https://github.com/juniorbaw
