# Modele Power BI — Fashion Retail Analytics

Source : les fichiers de `data/processed/` produits par dbt
(`make build && make export`). Charger de preference les `.parquet` : les types
arrivent corrects, sans etape de conversion manuelle.

---

## 1. Le modele relationnel

Schema en etoile : une table de faits au centre, des dimensions autour, aucune
relation entre dimensions.

```
                  dim_date
                      |
                      | 1 -> *  (date_key)
                      v
 dim_clients  ---->  fct_transactions  <----  dim_articles
              1 -> *                   * <- 1
             (client_key)                  (article_key)
```

### Relations a creer

| De (1) | Vers (*) | Cle | Cardinalite | Sens du filtre |
|---|---|---|---|---|
| `dim_clients[client_id]` | `fct_transactions[client_key]` | client | Un vers plusieurs | **Simple** |
| `dim_articles[article_key]` | `fct_transactions[article_key]` | article | Un vers plusieurs | **Simple** |
| `dim_date[date_key]` | `fct_transactions[date_key]` | date | Un vers plusieurs | **Simple** |

Les trois relations sont **actives** et **a sens unique** : la dimension filtre
les faits, jamais l'inverse.

### Marquer dim_date comme table de dates

Sans cette etape, aucune fonction de time intelligence (`TOTALYTD`,
`DATEADD`, `SAMEPERIODLASTYEAR`) ne fonctionne correctement.

1. Selectionner `dim_date`
2. Onglet Outils de table, **Marquer comme table de dates**
3. Choisir la colonne `date_jour` (le type date, pas `date_key` qui est un entier)

`dim_date` couvre 2022-10-02 a 2023-10-01 **sans trou** : c'est la condition
pour que Power BI accepte la table, et pour qu'un jour sans vente apparaisse
bien a zero dans une courbe au lieu d'etre saute.

### Tables a masquer

Masquer `mart_kpi_global`, `mart_segments` et `mart_produits` de la vue de
rapport, ou ne pas les importer du tout. Ce sont des agregats **deja calcules**
par dbt : ils servent a verifier les chiffres, pas a construire des visuels. Les
poser a cote de la table de faits sans relation invite au double comptage.

---

## 2. Les mesures DAX

Creer une table vide dediee (`Saisir des donnees` -> table `_Mesures`) et y
ranger toutes les mesures. Elles apparaissent alors regroupees en haut du volet
Champs.

### CA total

```dax
CA total =
SUM ( fct_transactions[montant_usd] )
```

### Nombre de transactions

```dax
Nb transactions =
COUNTROWS ( fct_transactions )
```

### Panier moyen

```dax
Panier moyen =
DIVIDE (
    [CA total],
    [Nb transactions]
)
```

`DIVIDE` plutot que `/` : il renvoie un blanc au lieu d'une erreur quand le
denominateur est zero, ce qui arrive des qu'un filtre vide la selection.

### Panier median

```dax
Panier median =
MEDIAN ( fct_transactions[montant_usd] )
```

La mediane vaut **110 USD** contre **156,71 USD** pour la moyenne. L'ecart n'est
pas du bruit : la distribution est asymetrique, tiree vers le haut par quelques
grosses transactions. C'est la mediane qui decrit l'achat typique.

### Nombre de clients distincts

```dax
Nb clients =
DISTINCTCOUNT ( fct_transactions[client_key] )
```

Compte sur la **table de faits**, pas sur `dim_clients` : ainsi la mesure
respecte les filtres. `COUNTROWS(dim_clients)` renverrait 166 meme filtre sur un
seul mois.

### Part du CA par segment

```dax
Pct CA segment =
DIVIDE (
    [CA total],
    CALCULATE (
        [CA total],
        REMOVEFILTERS ( dim_clients[segment_valeur] )
    )
)
```

`REMOVEFILTERS` sur la seule colonne de segment : le denominateur reste soumis
aux autres filtres (periode, article). Utiliser `ALL(fct_transactions)`
retirerait **tous** les filtres et donnerait des parts qui ne bougent plus quand
on change de mois.

### Note moyenne ponderee

```dax
Note moyenne ponderee =
DIVIDE (
    SUMX (
        FILTER ( fct_transactions, NOT ISBLANK ( fct_transactions[note_avis] ) ),
        fct_transactions[montant_usd] * fct_transactions[note_avis]
    ),
    CALCULATE (
        SUM ( fct_transactions[montant_usd] ),
        NOT ISBLANK ( fct_transactions[note_avis] )
    )
)
```

Un avis porte par 4 000 USD de ventes pese plus qu'un avis porte par 30 USD. Le
denominateur est restreint aux **memes lignes** que le numerateur : sinon la
note est diluee par le CA des transactions sans avis (263 des 2 750 lignes).

### CA cumule

```dax
CA cumule =
CALCULATE (
    [CA total],
    DATESYTD ( dim_date[date_jour] )
)
```

Pour un cumul depuis le debut du jeu de donnees plutot que depuis le 1er
janvier :

```dax
CA cumule total =
CALCULATE (
    [CA total],
    FILTER (
        ALLSELECTED ( dim_date[date_jour] ),
        dim_date[date_jour] <= MAX ( dim_date[date_jour] )
    )
)
```

### CA mois precedent

```dax
CA M-1 =
CALCULATE (
    [CA total],
    DATEADD ( dim_date[date_jour], -1, MONTH )
)
```

### Variation M-1 en pourcentage

```dax
Variation M-1 % =
VAR CaCourant = [CA total]
VAR CaPrecedent = [CA M-1]
RETURN
    IF (
        NOT ISBLANK ( CaPrecedent ),
        DIVIDE ( CaCourant - CaPrecedent, CaPrecedent )
    )
```

Le `IF` sur `ISBLANK` evite d'afficher une croissance de 100 % sur le premier
mois, ou il n'y a simplement pas de mois precedent.

---

## 3. Les pieges

### Relations bidirectionnelles

Power BI propose de passer une relation en filtrage **bidirectionnel** des qu'un
visuel ne renvoie pas ce qu'on attend. C'est presque toujours le mauvais
reflexe.

Avec trois dimensions autour d'une table de faits, deux relations
bidirectionnelles creent un **chemin de filtre ambigu** : `dim_clients` peut
filtrer `dim_articles` en passant par les faits. Le moteur choisit un chemin,
et le resultat devient dependant de l'ordre d'evaluation — donc imprevisible.

Garder les trois relations en sens simple. Quand un filtre croise est vraiment
necessaire, l'exprimer dans la mesure avec `CROSSFILTER` ou `TREATAS`, au cas
par cas et de maniere visible dans le code.

### Mesures et colonnes calculees

| | Colonne calculee | Mesure |
|---|---|---|
| Calculee | au chargement, ligne par ligne | a l'affichage, selon les filtres |
| Stockee | oui, occupe de la memoire | non |
| Contexte | ligne | filtre |

`Panier moyen` en **colonne calculee** donnerait une valeur figee par ligne,
puis Power BI en ferait la somme dans un visuel — un total qui ne veut rien
dire. En **mesure**, il se recalcule pour chaque cellule du tableau.

Regle : tout ce qui s'agrege est une mesure. Une colonne calculee ne se
justifie que pour un attribut servant a **filtrer ou grouper**
(`gamme_prix`, `segment_valeur`), et ces deux-la sont deja calcules par dbt.

### Faire le calcul en amont plutot que dans Power BI

`segment_valeur` et `gamme_prix` sont calcules par dbt, pas en DAX. Ils sont
donc **testes** (`accepted_values` dans `schema.yml`) et identiques dans tous
les outils qui liront ces tables. Une segmentation reecrite en DAX vit dans un
seul fichier `.pbix`, que personne ne peut relire ni tester.

---

## 4. Verifier le modele

Apres chargement, creer une carte avec chaque mesure et confronter aux valeurs
de reference de `mart_kpi_global.csv` :

| Mesure | Valeur attendue |
|---|---|
| CA total | 430 952 USD |
| Nb transactions | 2 750 |
| Nb clients | 166 |
| Panier moyen | 156,71 USD |
| Panier median | 110 USD |

Si `CA total` depasse largement 430 952, c'est un **fan-out** : une relation est
dans le mauvais sens, ou une table d'agregats client a ete importee a cote de la
table de faits. Voir `docs/rapport_qualite_donnees.md` — c'est exactement
l'erreur qui a produit un CA de 7,6 M sur la premiere version de ce projet.
