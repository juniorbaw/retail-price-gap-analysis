# Rapport de qualite des donnees — Fashion Retail Analytics

Source : `data/raw/Fashion_Retail_Sales.csv`
md5 : `68a05918d5982267fb5f7b250fb3f079` — 3 400 lignes, 6 colonnes, 133 Ko
Periode couverte : 2 octobre 2022 au 1er octobre 2023

Ce rapport documente le profilage de la source, puis une erreur de grain qui a
produit un chiffre d'affaires faux d'un facteur 17,6, publie pendant plusieurs
semaines. Il decrit la cause racine, la correction, et le test qui empeche sa
reapparition.

---

## 1. Profilage de la source

### Completude

| Colonne | Valeurs manquantes | Distinctes | Commentaire |
|---|---|---|---|
| `Customer Reference ID` | 0 (0 %) | 166 | Toujours renseigne |
| `Item Purchased` | 0 (0 %) | 50 | Toujours renseigne |
| `Purchase Amount (USD)` | **650 (19,1 %)** | 234 | Le seul trou significatif |
| `Date Purchase` | 0 (0 %) | 365 | Un jour par date, aucune date invalide |
| `Review Rating` | 324 (9,5 %) | 41 | Absence d'avis, pas une erreur |
| `Payment Method` | 0 (0 %) | 2 | `Cash`, `Credit Card` |

### Verifications structurelles

| Controle | Resultat |
|---|---|
| Lignes strictement dupliquees | 0 |
| Montants negatifs ou nuls | 0 |
| Dates non analysables en JJ-MM-AAAA | 0 |
| Notes hors de l'intervalle 1 a 5 | 0 |
| Identifiants client manquants | 0 |

### Decisions de nettoyage

**Les 650 lignes sans montant sont ecartees.** Une ligne sans montant ne peut
pas contribuer a une analyse de chiffre d'affaires. Elles sont filtrees une
seule fois, dans `stg_transactions`, et jamais reintroduites.

Consequence a connaitre : **aucun client ne disparait** de l'analyse. Les 166
clients ont chacun au moins une transaction valorisee. Le filtre reduit le
volume de transactions, pas la population client.

**Les notes manquantes sont conservees en NULL.** Les remplacer par 0
abaisserait artificiellement toutes les moyennes : une absence d'avis n'est pas
une mauvaise note. En NULL, les fonctions d'agregation les ignorent, ce qui est
le comportement voulu. Sur les 2 750 transactions retenues, 263 n'ont pas d'avis.

**La date est chargee en texte puis convertie explicitement.** La source est en
JJ-MM-AAAA. Laisser un moteur deviner le format ferait interpreter les 12
premiers jours de chaque mois en MM-JJ-AAAA, sans aucune erreur visible. Le
masque est donc impose : `strptime(colonne, '%d-%m-%Y')`.

### Volumetries de reference

| | Valeur |
|---|---|
| Lignes source | 3 400 |
| Transactions retenues | **2 750** |
| Clients | **166** |
| Articles | 50 |
| Jours couverts | 365 |

---

## 2. L'erreur de grain

### Le symptome

La premiere version du projet publiait, sur le README du portfolio et sur un CV :

> 2 750 transactions · 2 800 clients · CA 7,6 M€ · Panier moyen : 156,7 €

Trois de ces quatre chiffres sont faux, et ils sont incoherents entre eux :

```
2 750 transactions x 156,70 = 430 925    et non 7 600 000
```

Un lecteur qui pose cette multiplication voit l'incoherence en dix secondes.
Le chiffre reel est **430 952 USD**, soit **17,6 fois plus petit** que le
chiffre publie. Et 2 750 transactions pour 2 800 clients serait de toute facon
impossible : il y aurait plus de clients que d'achats.

### La cause racine

Le pipeline initial faisait, en pandas :

```python
# 1. Agregation au grain CLIENT
clients = df_clean.groupby("client_id").agg(
    nb_achats=("article", "count"),
    total_depense=("montant", "sum")
).reset_index()

# 2. Retour sur le grain TRANSACTION
df_final = df_clean.merge(clients, on="client_id")
df_final.to_csv("../data/fashion_looker.csv")
```

Apres le `merge`, `fashion_looker.csv` a **2 750 lignes** — une par transaction
— mais la colonne `total_depense` y porte le **CA du client**, recopie a
l'identique sur chacune de ses lignes.

Un client avec 16 achats a donc son CA total ecrit 16 fois. Sommer cette colonne
dans un outil de BI multiplie le CA de chaque client par son nombre d'achats :

```
CA reel      :   430 952 USD
CA fan-out   : 7 585 581 USD  =  430 952 x 16,57
```

`16,57` est exactement le nombre moyen de transactions par client. Le chiffre
publie, 7,6 M, est ce 7 585 581.

> **Le grain**, en trois lignes : le grain d'une table, c'est ce que represente
> une ligne. Ici, `fashion_looker.csv` est au grain *transaction*. Une metrique
> ne peut etre sommee que si elle est au meme grain que la table. `total_depense`
> est au grain *client* : dans une table au grain transaction, elle est dupliquee,
> et la sommer compte plusieurs fois la meme valeur. C'est ce qu'on appelle un
> **fan-out**.

### Pourquoi l'erreur n'a pas ete vue

Trois raisons, toutes structurelles plutot qu'individuelles :

1. **Aucune redondance.** Le CA n'etait calcule qu'a un seul endroit. Rien ne
   permettait de le confronter a une autre mesure de la meme grandeur.
2. **Un ordre de grandeur plausible.** 7,6 M€ pour un retailer fashion ne choque
   pas. Le chiffre n'est pas absurde en soi ; il n'est faux que rapporte aux
   2 750 transactions publiees a cote.
3. **Aucun test automatise.** Le pipeline etait decrit comme "de type dbt", avec
   une organisation en staging et marts, mais sans le mecanisme qui fait
   l'interet de dbt : les tests qui s'executent a chaque build.

### La correction

Trois changements, du plus local au plus structurel.

**1. Separer les grains.** `dim_clients` porte les agregats client
(`ca_client`, `nb_transactions`). `stg_transactions` porte les faits au grain
transaction. Les deux ne sont jamais fusionnes.

**2. Rendre le fan-out impossible dans le modele BI.** `fct_transactions` ne
contient que des cles etrangeres et des mesures au grain transaction. Aucun
agregat client n'y figure. Power BI retrouve `ca_client` par la relation vers
`dim_clients`, sans jamais le dupliquer dans la table de faits.

**3. Mesurer la meme grandeur a deux endroits.** Le CA est desormais calculable
depuis trois tables de grains differents. Ces trois valeurs doivent coincider.
C'est ce qu'un test verifie.

### Le test qui l'empeche de revenir

`dbt/tests/assert_coherence_ca.sql` :

```sql
with ca_transactions as (
    select sum(montant_usd) as ca from {{ ref('stg_transactions') }}
),
ca_clients as (
    select sum(ca_client) as ca from {{ ref('dim_clients') }}
)
select
    ca_transactions.ca as ca_grain_transaction,
    ca_clients.ca      as ca_grain_client,
    abs(ca_transactions.ca - ca_clients.ca) as ecart_usd
from ca_transactions
cross join ca_clients
where abs(ca_transactions.ca - ca_clients.ca) > 0.01
```

Le principe : mesurer **la meme grandeur a deux grains differents** et exiger
qu'elles tombent sur la meme valeur. Un test dbt echoue si sa requete renvoie
au moins une ligne — donc ici, si l'ecart depasse un centime.

Applique au pipeline fautif, ce test aurait renvoye :

| ca_grain_transaction | ca_grain_client | ecart_usd |
|---|---|---|
| 430 952,00 | 7 585 581,00 | 7 154 629,00 |

Le build aurait echoue, et le chiffre n'aurait jamais atteint un CV.

Cinq autres tests completent la protection :

| Test | Ce qu'il garantit |
|---|---|
| `assert_coherence_ca_etoile` | Le CA de la table de faits egale celui du staging, apres la jointure vers `dim_articles` |
| `assert_grain_dim_clients` | `COUNT(*) = COUNT(DISTINCT client_id)` dans la dimension client |
| `assert_kpi_arithmetique` | `nb_transactions x panier_moyen = ca_total` |
| `assert_parts_segments` | Les parts de segments totalisent 100 % |
| `assert_volumetrie` | Les 2 750 et 166 publies restent exacts |

`assert_volumetrie` merite un mot : il fige dans le code les chiffres cites dans
les README. Si la source change, le build echoue au lieu de rendre la
documentation silencieusement fausse. C'est une decision a prendre, pas un
chiffre a ajuster.

---

## 3. Deux autres chiffres publies qui ne se reproduisent pas

Le meme controle a ete applique aux autres affirmations du portfolio initial.

### « 2 800 clients »

La source contient **166** identifiants client distincts. Aucun decoupage du
fichier ne produit 2 800 : ni les lignes (3 400), ni les transactions valorisees
(2 750), ni les articles (50). Le chiffre est sans origine identifiable.

### « 8,9 % des clients VIP generent 54,1 % du CA »

La segmentation du projet utilise des **quartiles** (`pd.qcut(..., 4)` a
l'origine, `ntile(4)` aujourd'hui). Par construction, un quartile contient un
quart des clients : le segment VIP represente donc **24,7 %** des clients, pas
8,9 %.

Concentration reellement observee :

| Part des clients | Part du CA |
|---|---|
| 6,0 % (10 clients) | 17,3 % |
| **9,0 % (15 clients)** | **24,2 %** |
| 15,1 % (25 clients) | 36,1 % |
| **24,7 % (41 clients, le segment VIP)** | **50,8 %** |
| 50,0 % (83 clients) | 71,7 % |

A 9 % des clients, on est a 24,2 % du CA, pas a 54,1 %. Le couple (8,9 ; 54,1)
ne correspond a aucun point de cette courbe.

**Le chiffre correct, et il reste un bon argument :** *24,7 % des clients
generent 50,8 % du chiffre d'affaires*. La moitie du CA tient a un quart des
clients — c'est une concentration reelle, verifiable, et testee.

---

## 4. Limites de l'analyse

- **Une seule annee**, sans historique anterieur : aucune saisonnalite ne peut
  etre distinguee d'une tendance.
- **166 clients**, effectif faible. Un segment en compte une quarantaine : un
  seul gros acheteur deplace visiblement les moyennes de son segment.
- **19,1 % des lignes sans montant** sont ecartees. Si cette absence n'est pas
  aleatoire — par exemple concentree sur un canal de vente — les totaux sont
  biaises. La source ne permet pas de le verifier.
- **Aucune donnee de marge**, seulement du chiffre d'affaires. Un article a fort
  CA n'est pas necessairement un article rentable.
- **La segmentation est relative**, pas metier. Les quartiles decoupent la
  population en quatre parts egales ; ils ne disent pas ce qu'est un « bon »
  client dans l'absolu.
- **Aucune dimension geographique ni de canal** dans la source.

---

## 5. Reproduire ces controles

```bash
cd 02-fashion-retail-analytics
make setup     # installe dbt-duckdb et les dependances
make build     # dbt build : 1 seed + 8 modeles + 125 tests
```

`make build` echoue si un seul test casse. Les chiffres de ce rapport sortent
de `mart_kpi_global` et sont consultables apres le build :

```bash
make kpi
```
