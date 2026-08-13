# Analyse de positionnement prix — Mode et luxe

Pipeline de collecte via API, nettoyage et segmentation de prix sur un
echantillon de produits mode et luxe.

> **Chiffres non reproductibles en l'etat.** Le CSV collecte
> (`data/produits_clean.csv`) n'est pas versionne, et l'API Channel3 exige une
> cle. Les chiffres ci-dessous proviennent de la version precedente du projet et
> **n'ont pas pu etre recalcules**. Deux d'entre eux se contredisent (voir
> [Chiffres a verifier](#chiffres-a-verifier)). A traiter avant de mettre ce
> projet en avant.

---

## Objectif

Sur le marche du retail mode et luxe, les prix d'un meme type de produit varient
d'un facteur important selon la marque. Ce projet cartographie ces ecarts et
compare la politique de remise entre segments de prix.

## Demarche

1. **Extraction** — API Channel3, 6 categories (maroquinerie, chaussures,
   montres, manteaux, echarpes, lunettes) via `src/collecte.py`.
2. **Nettoyage** — suppression des produits sans prix, deduplication par `id`,
   restriction a l'USD pour comparer ce qui est comparable.
3. **Segmentation** — terciles de prix calcules **a l'interieur de chaque
   categorie**. Comparer une echarpe a une montre au prix absolu n'aurait aucun
   sens : chaque produit est situe par rapport aux autres de sa categorie.
4. **Analyse** — remise moyenne **ponderee**
   (`SUM(ecarts) / SUM(prix de reference)`), et comparaison moyenne / mediane.

### Pourquoi une remise ponderee

Une moyenne simple des pourcentages de remise donnerait le meme poids a une
echarpe a 40 USD qu'a une montre a 20 000 USD. La ponderation par le prix de
reference mesure la remise reellement consentie sur la valeur du catalogue.

## Insights

Ces trois observations sont qualitatives et restent valides independamment des
chiffres exacts a revalider.

1. **Le marche n'est pas un continuum, il est segmente.** L'ecart de prix entre
   le segment accessible et le segment luxe, pour un meme type de produit, se
   compte en ordre de grandeur, pas en pourcentage.
2. **La remise est inversement liee au prix.** Les marques premium protegent leur
   prix ; les marques accessibles utilisent la remise comme levier commercial.
3. **La distribution des prix est asymetrique.** La moyenne est tiree vers le
   haut par quelques pieces d'exception (montres). La mediane decrit mieux le
   produit typique.

## Chiffres a verifier

| Chiffre | Statut |
|---|---|
| 120 produits collectes | A recalculer |
| Remise moyenne ponderee 25,26 % | A recalculer |
| 39 % des produits avec prix de reference | A recalculer |
| Ecart de prix facteur ~20 accessible / luxe | A recalculer |
| **2 869 USD** | **Contradictoire** |

Le dernier point est bloquant. La version portfolio du projet presentait 2 869
USD comme le **prix median**, tandis que la version de ce depot le presentait
comme le **prix moyen**, en precisant que « la mediane est bien inferieure ».
Les deux affirmations sont incompatibles. Sans le CSV source, il est impossible
de trancher.

`src/nettoyage.py` produit `data/kpi_verifies.csv`, qui contient les deux
valeurs cote a cote (`prix_moyen_usd` et `prix_median_usd`) : rejouer la
collecte tranche la question et fournit tous les chiffres du tableau.

## Limites

- **Echantillon par mots-cles**, pas un recensement de marche : les resultats
  dependent des requetes envoyees a l'API.
- **Snapshot ponctuel**, sans dimension temporelle. Une remise observee un jour
  donne ne dit rien de la politique de prix sur l'annee.
- **Une minorite de produits communique un prix de reference.** L'analyse des
  remises ne porte que sur ce sous-ensemble, qui n'est probablement pas
  representatif : afficher un prix barre est deja une decision commerciale.
- **Retailers concentres** (Jomashop, Farfetch, TheRealReal) : le prix observe
  est celui du revendeur, pas celui de la marque.
- **Segmentation relative** par terciles : elle ne definit pas un seuil absolu
  de ce qu'est un produit « de luxe ».

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
exactement les memes chiffres. Il affiche `kpi_verifies.csv` en fin
d'execution.

Les notebooks reprennent la meme logique, pas a pas et commentee :

```bash
jupyter lab notebooks/
```

`01_collecte.ipynb` appelle l'API (ses sorties sont vides : il n'est pas
rejouable sans cle). `02_analyse.ipynb` porte le nettoyage et l'analyse.

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

Ce projet n'a **ni tests automatises ni modele dbt**. C'est un pipeline de
collecte, pas une transformation analytique — mais c'est aussi pour cela que ses
chiffres n'ont pas pu etre revalides automatiquement. Le projet
[02-fashion-retail-analytics](../02-fashion-retail-analytics/) montre l'approche
inverse : chaque chiffre publie y est couvert par un test qui echoue si le
chiffre devient faux.
