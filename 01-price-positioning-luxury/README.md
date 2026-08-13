# Analyse d'ecarts de prix — Marche mode et luxe

Collecte via API, nettoyage et segmentation de prix sur un echantillon de
produits mode et luxe. L'objet de l'analyse : mesurer l'ecart de prix entre
segments pour un meme type de produit, et comparer leur politique de remise.

---

## Chiffres cles

Source : `produits_clean.csv`, collecte API Channel3, prix en USD.

| Indicateur | Valeur |
|---|---|
| Produits collectes | **119** |
| Produits avec prix barre exploitable | **55** (46 %) |
| Prix median | **376 USD** |
| Prix moyen | **2 724,5 USD** |
| Remise moyenne simple (n = 55) | **39,4 %** |
| Remise moyenne ponderee | **23,3 %** |
| Correlation de rang prix / taux de remise (Spearman) | **-0,58** |

Les deux remises sont affichees separement et labellisees : elles ne mesurent
pas la meme chose (voir [Deux remises, deux questions](#deux-remises-deux-questions)).

### Par segment de prix

| Segment | Produits | Prix median | Remise ponderee |
|---|---|---|---|
| Accessible | 41 | 123 USD | **42,3 %** |
| Mid | 37 | 275 USD | **36,5 %** |
| Luxe | 41 | 1 667 USD | **19,9 %** |

Ratio des medianes Luxe / Accessible : **13,6**.
Ratio Watches / Shoes : **48,8**.

## Insights

**1. Le gradient de remise est monotone, et c'est la preuve la plus solide.**
42,3 % sur l'accessible, 36,5 % sur le mid, 19,9 % sur le luxe. La remise
decroit a chaque palier, sans exception. Le luxe ne se brade pas : il protege
son prix. Le Spearman de **-0,58** confirme la relation au niveau produit, pas
seulement au niveau segment.

**2. L'ecart de prix est un facteur 13,6, pas un continuum.** Entre la mediane
du segment accessible (123 USD) et celle du luxe (1 667 USD), pour des
categories comparables. Le marche est nettement segmente. Entre categories,
l'ecart est encore plus marque : facteur **48,8** entre les montres et les
chaussures.

**3. La moyenne est inexploitable sur cette distribution.** Prix median
**376 USD** contre prix moyen **2 724,5 USD**, soit un rapport de 7,2. Quelques
montres d'exception tirent la moyenne. Toute communication sur un « prix
moyen » de ce marche est trompeuse.

## Deux remises, deux questions

Les deux chiffres sont publies parce qu'ils repondent a des questions
differentes, et les confondre change la conclusion.

**Remise moyenne simple : 39,4 %.** Moyenne arithmetique des taux de remise.
Chaque produit pese pareil. Repond a : *quelle remise porte un produit pris au
hasard parmi ceux qui affichent un prix barre ?*

**Remise moyenne ponderee : 23,3 %.**
`SUM(prix_barre - prix) / SUM(prix_barre)`. Repond a : *quelle remise est
reellement consentie sur la valeur du catalogue ?*

L'ecart entre 39,4 % et 23,3 % n'est pas du bruit : il mesure le fait que les
produits chers sont moins remises. Une echarpe a 40 USD remisee de 50 % et une
montre a 20 000 USD remisee de 5 % donnent 27,5 % en moyenne simple, et 5,1 %
en pondere. La seconde decrit la politique commerciale, la premiere decrit
l'etalage.

## Limites

A lire en meme temps que les chiffres, pas apres.

- **L'echantillon n'est pas representatif.** Collecte par recherche par
  mots-cles, environ 20 resultats par requete : c'est un echantillon de moteur
  de recherche, pas un catalogue ni un recensement de marche. Les chiffres
  decrivent cet echantillon, pas le marche du luxe.
- **46 % de couverture sur le prix de reference.** Seuls 55 des 119 produits
  affichent un prix barre exploitable. Toute l'analyse de remise porte sur ce
  sous-ensemble — et **afficher un prix barre est deja une decision
  commerciale**, plus frequente chez les marques qui pratiquent la remise. La
  remise mesuree est donc probablement superieure a la remise reelle.
- **USD uniquement.** Les prix dans d'autres devises sont ecartes plutot que
  convertis : la source ne fournit pas de taux de change date.
- **Snapshot ponctuel.** Aucune dimension temporelle : impossible de distinguer
  une remise permanente d'une promotion.
- **Segmentation relative.** Les terciles sont calcules dans l'echantillon : un
  produit « Luxe » l'est par rapport aux autres produits collectes, pas dans
  l'absolu.
- **Prix revendeur**, pas prix marque. Les retailers dominants de l'echantillon
  fixent leurs propres prix.

## Ce qui a ete corrige

L'ancienne version du projet publiait un « prix median de 2 869 USD ». Ce
chiffre etait faux sur deux plans :

- **Mauvais label** : ce n'etait pas une mediane. La mediane reelle est
  **376 USD**.
- **Mauvaise methode** : 2 869 etait la moyenne des 6 prix moyens par requete —
  une moyenne de moyennes sur des groupes d'effectifs differents, qui ne
  correspond a aucune grandeur interpretable. La moyenne reelle est
  **2 724,5 USD**.

L'ecart de prix annonce a « un facteur ~20 » etait egalement surevalue : le
ratio des medianes Luxe / Accessible est de **13,6**.

## Reproduire ce projet

Prerequis : Python 3.11 ou plus, et une cle d'API Channel3.

```bash
git clone https://github.com/juniorbaw/retail-price-gap-analysis.git
cd retail-price-gap-analysis
pip install -r requirements.txt

# La cle n'est jamais versionnee : elle est lue depuis .env
echo "CHANNEL3_API_KEY=votre_cle" > 01-price-positioning-luxury/.env

cd 01-price-positioning-luxury
python src/collecte.py  --sortie data/produits_bruts.csv
python src/nettoyage.py --entree data/produits_bruts.csv \
                        --sortie data/produits_clean.csv \
                        --kpi    data/kpi_verifies.csv
```

`src/nettoyage.py` est deterministe : a partir du meme CSV brut, il reproduit
exactement les chiffres de ce README. Il ecrit `kpi_verifies.csv`, qui contient
`prix_moyen_usd` et `prix_median_usd` **cote a cote et nommes sans ambiguite** —
precisement pour que la confusion corrigee plus haut ne puisse pas se
reproduire.

Les notebooks reprennent la meme logique, pas a pas :

```bash
jupyter lab notebooks/
```

`01_collecte.ipynb` appelle l'API (sorties vides : non rejouable sans cle).
`02_analyse.ipynb` porte le nettoyage, la segmentation et les KPI.

> **Note sur la reproductibilite.** `produits_clean.csv` n'est pas versionne :
> il faut rejouer la collecte pour regenerer les chiffres. C'est la difference
> majeure avec le projet 02, dont la source est versionnee et dont chaque
> chiffre est verrouille par un test qui tourne en CI.

## Structure

```
01-price-positioning-luxury/
├── notebooks/
│   ├── 01_collecte.ipynb     extraction via l'API
│   └── 02_analyse.ipynb      nettoyage, segmentation, KPI
├── src/
│   ├── collecte.py           script parametre (--requetes, --sortie)
│   └── nettoyage.py          script parametre (--entree, --sortie, --kpi)
├── data/                     vide : les CSV ne sont pas versionnes
└── docs/
    └── methodologie.md       choix de methode et leurs justifications
```

## Stack

`Python 3.11` · `pandas` · `requests` · `API Channel3` · `Looker Studio`

## Ecart avec le projet 02

Ce projet n'a ni modele dbt ni tests automatises : c'est un pipeline de
collecte, pas une transformation analytique. C'est aussi pourquoi une erreur de
label a pu y survivre plusieurs semaines. Le projet
[02-fashion-retail-analytics](../02-fashion-retail-analytics/) montre l'approche
inverse : chaque chiffre publie y est couvert par un test qui casse le build
s'il devient faux.
