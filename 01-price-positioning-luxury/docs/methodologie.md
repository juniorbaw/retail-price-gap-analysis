# Methodologie — Analyse de positionnement prix

Ce document justifie les choix de methode. Chaque decision d'analyse ecarte des
alternatives : les expliciter permet de contester le resultat sur des bases
claires.

---

## 1. Constitution de l'echantillon

L'echantillon est constitue par **recherche par mots-cles** sur l'API Channel3,
six requetes couvrant des categories representatives du spectre mode et luxe :

| Requete | Categorie |
|---|---|
| `leather handbag` | Maroquinerie |
| `leather shoes` | Chaussures |
| `luxury watch` | Horlogerie |
| `wool coat` | Manteaux |
| `silk scarf` | Echarpes |
| `sunglasses` | Lunettes |

**Ce que ce n'est pas** : un recensement de marche. Les resultats dependent de
l'algorithme de recherche de l'API et du choix des mots-cles. Un echantillon
construit avec `designer handbag` au lieu de `leather handbag` donnerait une
distribution de prix differente.

Ce biais est assume : l'objectif est de comparer des **ecarts relatifs entre
segments**, pas d'estimer un prix moyen de marche absolu.

## 2. Regles de nettoyage

Appliquees dans cet ordre, par `src/nettoyage.py` :

**1. Retirer les produits sans prix.** Un produit sans prix ne peut pas
contribuer a une analyse de prix. Aucune imputation n'est tentee : estimer le
prix d'un produit de luxe a partir de sa categorie n'aurait pas de sens, l'ecart
intra-categorie etant precisement l'objet de l'etude.

**2. Dedupliquer par `id`.** Un meme produit peut remonter sur deux requetes
(une paire de bottes en cuir repond a `leather shoes` autant qu'a un autre
terme). Sans deduplication, il pese double.

**3. Ne conserver que l'USD.** Comparer des prix en devises differentes exige un
taux de change a une date donnee. La source n'en fournit pas, et un taux moyen
introduirait une erreur non mesurable. Restreindre a une seule devise est plus
honnete que convertir approximativement.

**Ce qui n'est pas fait** : aucun retrait de valeurs extremes. Les pieces
d'exception (montres a plusieurs dizaines de milliers de dollars) sont
**conservees**. Ce sont des observations reelles, et l'asymetrie de la
distribution est un resultat de l'analyse, pas un defaut a corriger.

## 3. Segmentation par terciles intra-categorie

C'est le choix de methode le plus structurant.

**Le probleme.** Segmenter sur le prix absolu, toutes categories confondues,
placerait mecaniquement toutes les montres dans le segment « luxe » et toutes
les echarpes dans « accessible ». On mesurerait alors la difference de prix
entre categories de produits, pas le positionnement des marques.

**La solution.** Les terciles sont calcules **a l'interieur de chaque
categorie**. Une echarpe est comparee aux autres echarpes, une montre aux autres
montres.

```python
df.groupby("requete", group_keys=False).apply(_label_groupe)
```

| Segment | Definition | Produits | Prix median | Remise ponderee |
|---|---|---|---|---|
| `1. Accessible` | Prix <= tercile bas (33 %) de sa categorie | 41 | 123 USD | 42,3 % |
| `2. Mid` | Entre les deux terciles | 37 | 275 USD | 36,5 % |
| `3. Luxe` | Prix > tercile haut (66 %) de sa categorie | 41 | 1 667 USD | 19,9 % |

Le gradient de remise est **monotone** : il decroit a chaque palier, sans
exception. C'est la preuve la plus solide du projet, parce qu'elle ne repose pas
sur un seul chiffre mais sur un ordre.

**Consequence a garder en tete.** La segmentation est **relative**. Chaque
segment contient environ un tiers des produits de chaque categorie, par
construction. Un produit classe « Luxe » l'est relativement a sa categorie dans
cet echantillon, pas dans l'absolu. Un ecart de prix entre segments ne dit donc
rien sur le niveau de prix du marche : il dit que la dispersion intra-categorie
est forte.

## 4. Remise moyenne ponderee

La remise est calculee sur les produits affichant un prix de reference
(`prix_barre`), avec la formule :

```
remise = SUM(prix_barre - prix) / SUM(prix_barre)
```

**Pourquoi pas une moyenne des pourcentages.** `AVG((prix_barre - prix) / prix_barre)`
donnerait le meme poids a une echarpe a 40 USD remisee de 50 % qu'a une montre a
20 000 USD remisee de 5 %. La moyenne simple decrit le comportement d'un
produit tire au hasard ; la moyenne ponderee decrit la remise reellement
consentie sur la valeur du catalogue. Pour une question de politique
commerciale, c'est la seconde qui repond.

Sur cet echantillon, l'ecart entre les deux est large : **39,4 %** en moyenne
simple contre **23,3 %** en pondere. Cet ecart n'est pas du bruit, c'est le
resultat lui-meme : il mesure le fait que les produits chers sont nettement
moins remises. Les deux chiffres sont donc publies cote a cote et labellises,
jamais l'un a la place de l'autre.

**Le biais de selection, lui, ne se corrige pas.** Seuls 55 des 119 produits
(46 %) communiquent un prix de reference. Ces produits ne sont pas un
echantillon aleatoire : **afficher un prix barre est deja une decision
commerciale**, plus frequente chez les marques qui pratiquent la remise. La
remise moyenne mesuree est donc probablement **superieure** a la remise reelle
du marche. Cette limite est structurelle et doit accompagner tout chiffre de
remise cite.

## 5. Moyenne et mediane

Les deux sont produites, volontairement, dans `data/kpi_verifies.csv`
(`prix_moyen_usd` et `prix_median_usd`).

Sur une distribution asymetrique — et une distribution de prix l'est presque
toujours — la moyenne est tiree vers le haut par les valeurs extremes. La
mediane decrit mieux le produit typique.

**Citer l'une pour l'autre est une erreur de fond**, pas une imprecision de
vocabulaire. Ici, prix median **376 USD** contre prix moyen **2 724,5 USD** : un
rapport de 7,2.

C'est exactement l'erreur qui avait ete commise. La version precedente publiait
un « prix median de 2 869 USD », qui n'etait ni une mediane ni le prix moyen :
c'etait la **moyenne des six prix moyens par requete**. Une moyenne de moyennes
sur des groupes d'effectifs differents ne correspond a aucune grandeur
interpretable — elle donne le meme poids a une requete qui a remonte 15 produits
et a une qui en a remonte 25.

Double lecon : le **label** doit dire ce que le chiffre est, et la **methode**
d'agregation doit etre choisie, pas subie. D'ou l'export des deux valeurs par
`src/nettoyage.py`, nommees `prix_moyen_usd` et `prix_median_usd`, calculees
directement sur les 119 produits.

## 6. Ce qui manquerait pour aller plus loin

- **Une dimension temporelle.** Un snapshot ne distingue pas une remise
  permanente d'une promotion ponctuelle. Une collecte hebdomadaire sur trois
  mois repondrait a la question, et transformerait l'analyse descriptive en
  analyse de politique de prix.
- **Le prix officiel de la marque**, en plus du prix revendeur. L'ecart entre
  les deux mesure le pouvoir de negociation du retailer.
- **Des tests automatises.** Le projet 02 de ce portfolio montre la difference
  que cela fait : sans test, un chiffre faux reste faux tant que personne ne le
  recalcule a la main.
