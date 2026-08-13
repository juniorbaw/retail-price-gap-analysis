# Portfolio Data Analytics — Souleymane Ndiaye

[![CI](https://github.com/juniorbaw/retail-price-gap-analysis/actions/workflows/ci.yml/badge.svg)](https://github.com/juniorbaw/retail-price-gap-analysis/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Data Analyst — Retail & Luxe.** SQL, dbt, Python, Power BI.

Deux projets. Dans le premier, chaque chiffre publie est verrouille par un test
automatise qui fait echouer le build s'il devient faux. Le second est un
pipeline de collecte via API, dont les chiffres sont explicitement signales
comme a revalider.

---

## [02 — Fashion Retail Analytics](02-fashion-retail-analytics/) · projet principal

**Un modele dimensionnel teste, construit avec dbt sur DuckDB.** Reproductible
en deux commandes, sans compte cloud.

| | |
|---|---|
| Transactions | **2 750** |
| Clients | **166** |
| Chiffre d'affaires | **430 952 USD** |
| Panier moyen / median | 156,71 / 110,00 USD |
| Tests a chaque build | **125** |

**L'insight** : le segment VIP represente **24,7 % des clients et 50,8 % du
chiffre d'affaires**. La moitie du CA tient a un quart des clients.

**Ce que le projet raconte vraiment** : la premiere version publiait un CA de
7,6 M — **17,6 fois trop eleve**, soit exactement le nombre moyen de
transactions par client. Un agregat au grain client avait ete recopie sur chaque
ligne de transaction, puis somme. Le chiffre est parti sur un CV.

Le test `assert_coherence_ca` mesure aujourd'hui le CA a deux grains differents
et exige qu'ils coincident. Sur le pipeline fautif, il aurait renvoye un ecart
de 7 154 629 USD et casse le build.

Cause racine, correction et test : [rapport de qualite des donnees](02-fashion-retail-analytics/docs/rapport_qualite_donnees.md).

`dbt-core` · `dbt-duckdb` · `DuckDB` · `Parquet` · modele Power BI documente

---

## [01 — Positionnement prix, mode et luxe](01-price-positioning-luxury/)

**Pipeline de collecte via API et segmentation de prix** sur six categories
mode et luxe.

Segmentation par terciles calcules **a l'interieur de chaque categorie** :
comparer une echarpe a une montre au prix absolu n'aurait pas de sens.

**L'insight** : la remise est inversement liee au prix. Les marques premium
protegent leur prix, les marques accessibles utilisent la remise comme levier
commercial.

> **Chiffres a revalider.** Le CSV collecte n'est pas versionne et l'API exige
> une cle : les chiffres de ce projet n'ont pas pu etre recalcules, et deux
> d'entre eux se contredisent. Le detail est documente dans le
> [README du projet](01-price-positioning-luxury/#chiffres-a-verifier) plutot
> que masque.

`Python` · `pandas` · `API Channel3` · `Looker Studio`

---

## Stack

**Transformation** dbt-core 1.12, dbt-duckdb, dbt_utils
**Bases** DuckDB, SQL (variantes Snowflake documentees)
**Langage** Python 3.11, pandas
**BI** Power BI (modele en etoile + mesures DAX), Looker Studio
**Qualite** 125 tests dbt, GitHub Actions
**Formats** CSV, Parquet

## Ce que ce depot cherche a montrer

- **Un chiffre publie doit etre teste.** `assert_volumetrie` fige les 2 750 et
  166 cites dans ce README : si la source change, le build echoue au lieu de
  laisser la documentation devenir fausse en silence.
- **Le grain avant tout.** Faits et agregats sont separes, et la table de faits
  ne porte aucun agregat client — le fan-out devient structurellement
  impossible.
- **La reproductibilite se verifie.** DuckDB tourne en local : `make setup &&
  make build`, et un lecteur obtient les memes chiffres.
- **Les limites font partie du travail.** Chaque projet a une section Limites, et
  les chiffres non reproductibles sont signales comme tels.

## Reproduire

```bash
git clone https://github.com/juniorbaw/retail-price-gap-analysis.git
cd retail-price-gap-analysis
make setup     # dependances Python + packages dbt
make build     # 1 seed + 8 modeles + 125 tests
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
