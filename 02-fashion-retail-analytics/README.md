# Fashion Retail Analytics

Transformation de transactions brutes en modele analytique teste, avec dbt.

**Catalogue dbt et graphe de lineage** : voir [Publier le catalogue](#publier-le-catalogue)
— a activer une fois dans les reglages GitHub Pages.

---

## Objectif

Un fichier de 3 400 transactions, sans identifiant de transaction, avec 19 % de
montants manquants et des dates ambigues. En sortir un modele dimensionnel
exploitable en BI, dont **chaque chiffre est verifie par un test automatise**.

Le projet existait avant sous forme de notebook pandas decrit comme
« architecture de type dbt ». Il a produit un chiffre d'affaires faux d'un
facteur 17,6, publie sur un CV. C'est maintenant un vrai projet dbt, et le test
qui aurait attrape l'erreur fait partie du build.

## Chiffres cles

Tous produits par `mart_kpi_global`, tous couverts par un test.

| Indicateur | Valeur |
|---|---|
| Transactions | **2 750** (sur 3 400 lignes source) |
| Clients | **166** |
| Chiffre d'affaires | **430 952 USD** |
| Panier moyen | 156,71 USD |
| Panier median | 110,00 USD |
| Articles | 50 |
| Periode | 2022-10-02 au 2023-10-01 |

## Insights

**1. La moitie du CA tient a un quart des clients.** Le segment VIP represente
24,7 % des clients (41 sur 166) et **50,8 %** du chiffre d'affaires. Le
quartile le plus faible, a effectif quasi identique (42 clients), n'en pese que
12,0 %. Un client VIP vaut en moyenne 4,3 fois un client occasionnel.

**2. La moyenne ment sur le panier.** 156,71 USD de panier moyen contre 110,00
USD de median : la distribution est asymetrique, tiree par quelques grosses
transactions (jusqu'a 4 932 USD). Piloter sur la moyenne surestime l'achat
typique de 42 %.

**3. Un chiffre faux survit tant que rien ne le contredit.** Le CA publie
initialement, 7,6 M, etait 17,6 fois trop eleve — exactement le nombre moyen de
transactions par client. Aucune verification ne croisait deux mesures de la meme
grandeur. C'est ce qu'un test de coherence corrige, et c'est le vrai sujet de ce
projet.

## Methode

```
data/raw/Fashion_Retail_Sales.csv      source, jamais modifiee
        |
        v  seed dbt (lien symbolique, pas de copie)
   stg_transactions      grain transaction   2 750 lignes
        |
        +--> dim_clients      grain client   166 lignes
        |
        v
   fct_transactions + dim_articles + dim_date      schema en etoile
        |
        v
   mart_kpi_global · mart_segments · mart_produits
```

**Staging en vues, marts en tables.** Le staging ne fait que renommer, caster et
filtrer : le materialiser couterait du stockage pour aucun gain. Les marts
agregent et sont lus souvent : leur cout de calcul est paye une fois au build.

**Les grains sont separes.** Les agregats client vivent dans `dim_clients`. La
table de faits ne porte que des cles et des mesures au grain transaction. Cette
separation rend le fan-out structurellement impossible.

### Tests

125 tests a chaque build.

| Type | Contenu |
|---|---|
| Natifs | `unique`, `not_null`, `accepted_values`, `relationships` sur chaque colonne declaree |
| Intervalles | `dbt_utils.accepted_range` sur les montants et les notes |
| Singuliers | 6 tests metier dans `dbt/tests/` |

Les six tests singuliers :

| Test | Garantie |
|---|---|
| `assert_coherence_ca` | Le CA mesure au grain transaction egale celui mesure au grain client |
| `assert_coherence_ca_etoile` | Le CA de la table de faits resiste a la jointure vers `dim_articles` |
| `assert_grain_dim_clients` | `COUNT(*) = COUNT(DISTINCT client_id)` |
| `assert_kpi_arithmetique` | `nb_transactions x panier_moyen = ca_total` |
| `assert_parts_segments` | Les parts de segments totalisent 100 % |
| `assert_volumetrie` | Les 2 750 et 166 publies restent exacts |

Le premier est celui qui aurait attrape le bug de grain : il aurait renvoye un
ecart de 7 154 629 USD et fait echouer le build.

## Limites

- **Une seule annee**, sans historique : impossible de distinguer saisonnalite
  et tendance.
- **166 clients**, effectif faible. Un segment en compte une quarantaine : un
  seul gros acheteur deplace visiblement les moyennes.
- **19,1 % des lignes sans montant** sont ecartees. Si cette absence n'est pas
  aleatoire, les totaux sont biaises — la source ne permet pas de le verifier.
  Aucun client ne disparait pour autant : les 166 ont tous au moins une
  transaction valorisee.
- **Aucune donnee de marge.** Un article a fort CA n'est pas forcement rentable.
- **Segmentation relative**, par quartiles : elle ne definit pas un seuil metier
  absolu de ce qu'est un « bon » client.
- **Ni geographie ni canal** dans la source.
- **`note_moyenne` a 2,99 sur 5** : c'est une note basse, mais la source ne
  documente ni son echelle ni son mode de collecte. A ne pas interpreter comme
  un indicateur de satisfaction.

## Reproduire ce projet

Prerequis : Python 3.11 ou plus. Aucun compte cloud, aucun warehouse.

```bash
git clone https://github.com/juniorbaw/retail-price-gap-analysis.git
cd retail-price-gap-analysis/02-fashion-retail-analytics

make setup     # pip install -r ../requirements.txt && dbt deps
make build     # 1 seed + 8 modeles + 125 tests
```

`make build` echoue si un seul test casse.

Autres commandes :

```bash
make test      # tests seuls, sans reconstruire
make kpi       # affiche les chiffres de reference
make export    # regenere data/processed/ en CSV et Parquet
make docs      # genere le catalogue et le lineage
make clean     # supprime la base et les artefacts
```

Sans `make`, tout passe par dbt directement :

```bash
cd dbt
dbt deps
dbt build --profiles-dir .
```

Le profil DuckDB est versionne et ne contient aucun identifiant : il n'y a rien
a configurer.

### Publier le catalogue

`make docs` produit un site statique dans `dbt/target/` (`index.html`,
`manifest.json`, `catalog.json`), avec le graphe de lineage cliquable.

Pour le publier sur GitHub Pages :

```bash
make docs
mkdir -p ../docs-site
cp dbt/target/index.html dbt/target/manifest.json dbt/target/catalog.json ../docs-site/
git add ../docs-site && git commit -m "docs: publish dbt catalog"
git push
```

Puis, dans les reglages du depot : **Settings > Pages > Source: Deploy from a
branch**, dossier `/docs-site`. Le catalogue sera servi a
`https://juniorbaw.github.io/retail-price-gap-analysis/`.

Cette etape demande un acces aux reglages du depot et reste **a faire
manuellement**.

## Structure

```
02-fashion-retail-analytics/
├── data/
│   ├── raw/                 source, md5 verifie, jamais modifiee
│   └── processed/           7 tables en CSV et Parquet
├── dbt/
│   ├── models/staging/      stg_transactions, dim_clients
│   ├── models/marts/        etoile + marts d'analyse
│   ├── models/snowflake/    equivalents Snowflake (desactives)
│   ├── tests/               6 tests singuliers
│   ├── macros/              exporter_marts
│   └── seeds/               lien symbolique vers data/raw
├── docs/
│   ├── rapport_qualite_donnees.md    profilage, bug de grain, correction
│   ├── data_catalog.md               dictionnaire + glossaire
│   └── PORTABILITE.md                differences DuckDB / Snowflake
└── dashboard/
    └── POWER_BI.md          modele relationnel + 10 mesures DAX
```

## Stack

`dbt-core 1.12` · `dbt-duckdb 1.11` · `DuckDB 1.5` · `dbt_utils` · `Python 3.11`
· `Parquet` · `Power BI` (modele documente)
