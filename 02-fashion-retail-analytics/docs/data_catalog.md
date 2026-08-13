# Catalogue de donnees — Fashion Retail Analytics

Dictionnaire des tables produites par dbt, et glossaire des termes metier.

Le catalogue interactif genere par `dbt docs generate` contient les memes
informations plus le graphe de lineage. Ce fichier existe pour etre lisible
directement dans GitHub, sans rien lancer.

Convention de lecture : le **grain** d'une table indique ce que represente une
ligne. C'est la premiere chose a verifier avant d'agreger quoi que ce soit.

---

## Vue d'ensemble

| Table | Couche | Grain | Lignes | Role |
|---|---|---|---|---|
| `fashion_retail_sales` | seed | 1 ligne source | 3 400 | Source brute, non modifiee |
| `stg_transactions` | staging | 1 transaction | 2 750 | Faits nettoyes |
| `dim_clients` | staging | 1 client | 166 | Dimension client + agregats |
| `fct_transactions` | marts | 1 transaction | 2 750 | Table de faits (etoile) |
| `dim_articles` | marts | 1 article | 50 | Dimension article |
| `dim_date` | marts | 1 jour | 365 | Dimension calendaire |
| `mart_kpi_global` | marts | 1 ligne | 1 | Chiffres de reference |
| `mart_segments` | marts | 1 segment | 4 | Performance par segment |
| `mart_produits` | marts | 1 article | 50 | Performance par article |

---

## fct_transactions

Table de faits du schema en etoile. **Grain : une transaction.** 2 750 lignes.

| Colonne | Type | Description |
|---|---|---|
| `transaction_key` | BIGINT | Cle primaire. Substitution generee : la source n'a pas d'identifiant de transaction. |
| `client_key` | INTEGER | Cle etrangere vers `dim_clients.client_id`. |
| `article_key` | BIGINT | Cle etrangere vers `dim_articles.article_key`. |
| `date_key` | INTEGER | Cle etrangere vers `dim_date.date_key`, au format AAAAMMJJ. |
| `montant_usd` | DOUBLE | Montant de la transaction. **Mesure additive.** |
| `note_avis` | DOUBLE | Note de 1 a 5. **Mesure semi-additive** : se moyenne, ne se somme pas. NULL si pas d'avis. |
| `mode_paiement` | VARCHAR | `Cash` ou `Credit Card`. Dimension degeneree. |
| `date_achat` | DATE | Date de la transaction, en clair a cote de `date_key`. |

Cette table ne contient **aucun agregat client**, deliberement. Voir
`rapport_qualite_donnees.md`.

## dim_clients

**Grain : un client.** 166 lignes.

| Colonne | Type | Description |
|---|---|---|
| `client_id` | INTEGER | Cle primaire. |
| `nb_transactions` | BIGINT | Nombre de transactions du client. **Grain client.** |
| `ca_client` | DOUBLE | CA total du client. **Grain client** : ne jamais sommer depuis une table au grain transaction. |
| `panier_moyen_client` | DOUBLE | Montant moyen d'une transaction du client. |
| `panier_median_client` | DOUBLE | Montant median d'une transaction du client. |
| `montant_min_client` | DOUBLE | Plus petite transaction du client. |
| `montant_max_client` | DOUBLE | Plus grosse transaction du client. |
| `date_premier_achat` | DATE | Date de la premiere transaction. |
| `date_dernier_achat` | DATE | Date de la derniere transaction. Base d'une analyse de recence. |
| `nb_avis` | BIGINT | Nombre d'avis deposes. Peut valoir 0. |
| `note_moyenne_client` | DOUBLE | Note moyenne. NULL si le client n'a jamais note. |
| `quartile_valeur` | BIGINT | Quartile de CA, 1 a 4. |
| `segment_valeur` | VARCHAR | Libelle du segment, derive du quartile. |

## dim_articles

**Grain : un article.** 50 lignes. Attributs descriptifs uniquement, aucune
mesure de performance : celles-ci vivent dans `mart_produits`.

| Colonne | Type | Description |
|---|---|---|
| `article_key` | BIGINT | Cle primaire de substitution. |
| `article_nom` | VARCHAR | Libelle de l'article. Unique. |
| `prix_median_usd` | DOUBLE | Prix median observe. Sert a classer l'article en gamme. |
| `gamme_prix` | VARCHAR | `1. Entree de gamme`, `2. Milieu de gamme`, `3. Haut de gamme`. Terciles du prix median. |
| `date_premiere_vente` | DATE | Premiere vente observee. |
| `date_derniere_vente` | DATE | Derniere vente observee. |

## dim_date

**Grain : un jour.** 365 lignes, du 2022-10-02 au 2023-10-01, **sans trou**.

| Colonne | Type | Description |
|---|---|---|
| `date_key` | INTEGER | Cle primaire au format AAAAMMJJ. |
| `date_jour` | DATE | La date. C'est cette colonne qui doit etre declaree comme table de dates dans Power BI. |
| `annee` | BIGINT | Annee sur 4 chiffres. |
| `trimestre` | BIGINT | 1 a 4. |
| `mois` | BIGINT | 1 a 12. |
| `mois_nom` | VARCHAR | Nom du mois en anglais. |
| `jour` | BIGINT | Jour du mois, 1 a 31. |
| `semaine_iso` | BIGINT | Numero de semaine ISO 8601. |
| `jour_semaine_num` | BIGINT | 1 = lundi ... 7 = dimanche (ISO). |
| `jour_semaine_nom` | VARCHAR | Nom du jour en anglais. |
| `est_weekend` | BOOLEAN | Vrai samedi et dimanche. |
| `annee_mois` | VARCHAR | Cle de tri `AAAA-MM`. |
| `annee_trimestre` | VARCHAR | Cle de tri `AAAA-Tn`. |
| `debut_mois` | DATE | Premier jour du mois. |
| `debut_semaine` | DATE | Premier jour de la semaine (lundi). |

## mart_kpi_global

**Grain : une ligne.** Source de verite des chiffres publies.

| Colonne | Type | Valeur | Description |
|---|---|---|---|
| `nb_clients` | BIGINT | 166 | Clients distincts. |
| `nb_transactions` | BIGINT | 2 750 | Transactions valorisees. |
| `ca_total_usd` | DOUBLE | 430 952 | CA total. |
| `panier_moyen_usd` | DOUBLE | 156,71 | Montant moyen. Non arrondi. |
| `panier_median_usd` | DOUBLE | 110,00 | Montant median. |
| `montant_min_usd` | DOUBLE | 10 | Plus petite transaction. |
| `montant_max_usd` | DOUBLE | 4 932 | Plus grosse transaction. |
| `transactions_par_client` | DOUBLE | 16,57 | Facteur exact d'un eventuel fan-out. |
| `nb_articles_distincts` | BIGINT | 50 | Articles distincts. |
| `nb_avis` | BIGINT | 2 487 | Transactions avec avis. |
| `note_moyenne` | DOUBLE | 2,99 | Note moyenne sur les transactions notees. |
| `date_debut` | DATE | 2022-10-02 | Premiere transaction. |
| `date_fin` | DATE | 2023-10-01 | Derniere transaction. |

## mart_segments

**Grain : un segment de valeur.** 4 lignes.

| Colonne | Type | Description |
|---|---|---|
| `segment_valeur` | VARCHAR | Libelle du segment. |
| `nb_clients` | BIGINT | Clients du segment. |
| `ca_segment_usd` | DOUBLE | CA cumule du segment. |
| `ca_moyen_par_client` | DOUBLE | CA moyen d'un client du segment. |
| `transactions_par_client` | DOUBLE | Transactions moyennes par client du segment. |
| `panier_moyen_usd` | DOUBLE | Moyenne des paniers moyens **des clients**. Moyenne de moyennes, pas le panier moyen au grain transaction. |
| `ca_client_min` | DOUBLE | Borne basse du quartile. |
| `ca_client_max` | DOUBLE | Borne haute du quartile. |
| `pct_clients` | DOUBLE | Part de l'effectif client. Somme = 100. |
| `pct_ca` | DOUBLE | Part du CA. Somme = 100. |

Valeurs actuelles :

| Segment | Clients | % clients | CA (USD) | % CA |
|---|---|---|---|---|
| 1. Occasionnel | 42 | 25,3 | 51 543 | 12,0 |
| 2. Regulier | 41 | 24,7 | 70 477 | 16,4 |
| 3. Fidele | 41 | 24,7 | 87 279 | 20,3 |
| 4. VIP | 42 | 25,3 | 221 653 | 51,4 |

## mart_produits

**Grain : un article.** 50 lignes. Table d'analyse, distincte de `dim_articles`.

| Colonne | Type | Description |
|---|---|---|
| `article` | VARCHAR | Libelle de l'article. |
| `nb_transactions` | BIGINT | Transactions sur cet article. |
| `nb_clients` | BIGINT | Clients distincts ayant achete l'article. |
| `ca_article_usd` | DOUBLE | CA genere par l'article. |
| `panier_moyen_usd` | DOUBLE | Montant moyen d'une transaction. |
| `panier_median_usd` | DOUBLE | Montant median d'une transaction. |
| `montant_min_usd` | DOUBLE | Plus petite transaction. |
| `montant_max_usd` | DOUBLE | Plus grosse transaction. |
| `nb_avis` | BIGINT | Avis deposes sur l'article. |
| `note_moyenne_simple` | DOUBLE | Moyenne arithmetique des notes. |
| `note_moyenne_ponderee` | DOUBLE | Moyenne ponderee par le montant. NULL si aucun avis. |
| `pct_ca` | DOUBLE | Part de l'article dans le CA total. |
| `rang_ca` | BIGINT | Rang par CA decroissant, 1 a 50. |

---

# Glossaire metier

**Grain**
Ce que represente une ligne d'une table. Le grain de `fct_transactions` est la
transaction ; celui de `dim_clients` est le client. Une metrique ne peut etre
sommee que si elle est au meme grain que la table qui la porte.

**Fan-out**
Duplication de lignes provoquee par une jointure vers une table de grain plus
fin. Sommer une colonne dupliquee compte plusieurs fois la meme valeur. C'est
l'erreur qui a produit un CA de 7,6 M au lieu de 430 952. Voir
`rapport_qualite_donnees.md`.

**Mesure additive / semi-additive / non additive**
Une mesure **additive** se somme sur toutes les dimensions (`montant_usd`).
Une mesure **semi-additive** se somme sur certaines dimensions seulement (un
stock se somme par entrepot, pas dans le temps). Une mesure **non additive** ne
se somme jamais : une note, un taux, un ratio. `note_avis` se moyenne.

**Table de faits / dimension**
Une **table de faits** contient des evenements mesurables et des cles etrangeres
(`fct_transactions`). Une **dimension** contient les attributs descriptifs par
lesquels on filtre et on regroupe (`dim_clients`, `dim_articles`, `dim_date`).

**Schema en etoile**
Modele ou une table de faits centrale est entouree de dimensions reliees
directement a elle, sans relation entre dimensions. C'est ce que les outils de
BI consomment le plus efficacement, et cela limite les chemins de filtre
ambigus.

**Dimension degeneree**
Attribut stocke dans la table de faits parce qu'il decrit la transaction
elle-meme et non une entite externe. `mode_paiement` en est une : lui creer une
dimension a deux lignes n'apporterait rien.

**Cle de substitution**
Identifiant technique cree par le pipeline quand la source n'en fournit pas
(`transaction_key`, `article_key`). Il est stable tant que la source ne change
pas, et il evite de joindre sur du texte.

**Materialization dbt**
Facon dont dbt stocke le resultat d'un modele. Une **view** ne stocke rien et
recalcule a chaque lecture : c'est le bon choix pour du staging, qui ne fait que
renommer et caster. Une **table** stocke le resultat : c'est le bon choix pour
un mart, lu souvent et couteux a agreger. Il existe aussi `incremental` (ne
traiter que les nouvelles lignes) et `ephemeral` (interpole comme un CTE, jamais
materialise).

**Semantic layer**
Couche ou les indicateurs sont definis une fois, dans le depot, plutot que
reecrits dans chaque outil de BI. « Panier moyen » y a une definition unique et
testee, au lieu de trois variantes divergentes entre Power BI, Looker et un
tableur. Les marts de ce projet jouent ce role : les chiffres sortent de
`mart_kpi_global`, pas d'un calcul refait dans le dashboard.

**Segmentation par quartiles**
Decoupage de la population en quatre groupes, ordonnes par une mesure (ici le CA
client). C'est une segmentation **relative** : le segment VIP contient environ un
quart des clients par construction, quel que soit leur niveau de depense reel.
Elle ne definit pas un seuil metier absolu.

Deux decoupages coexistent et ne donnent pas le meme resultat. Le decoupage par
**bornes de valeur** (`qcut`, retenu ici) coupe aux valeurs de quantile et
accepte des groupes de tailles inegales : 42/41/41/42. Le decoupage par
**effectifs egaux** (`ntile`) force des groupes de meme taille et deplace des
clients de part et d'autre de la borne : 42/42/41/41. Sur ce jeu de donnees,
l'ecart de CA VIP entre les deux methodes est de 2 857 USD.

**Panier moyen / panier median**
Le **panier moyen** est le CA divise par le nombre de transactions (156,71 USD).
Le **panier median** est le montant qui separe la moitie basse de la moitie
haute (110 USD). L'ecart entre les deux mesure l'asymetrie de la distribution :
ici, quelques grosses transactions tirent la moyenne vers le haut, et c'est la
mediane qui decrit l'achat typique.
