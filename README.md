# Analyse d'écarts de prix — Retail mode & luxe

> **Statut : refonte en cours.** Les indicateurs de la première version comportaient trois erreurs
> de définition (une médiane calculée comme une moyenne de moyennes, deux mesures de remise
> confondues, une volumétrie erronée). Les chiffres corrigés figurent ci-dessous ; le tableau de
> bord est en cours de reconstruction.

> Pipeline data complet : extraction API → nettoyage Python → analyse → dashboard.
> Comment les marques de mode et de luxe se positionnent-elles en prix,
> et comment utilisent-elles la remise selon leur segment ?

![Dashboard](./dashboard.png)

🔗 **Dashboard interactif** : [voir sur Looker Studio](https://datastudio.google.com/s/kM3NfWMzsAg)

---

## Le problème

Sur le marché du retail mode/luxe, les prix pour un même type de produit
varient énormément selon la marque. Cette analyse cartographie ces écarts
et révèle comment la politique de remise diffère entre segments.

## La démarche (pipeline de bout en bout)

1. **Extraction** — API Channel3 (Python, `requests`) : 120 produits sur 6 catégories
   (maroquinerie, chaussures, montres, manteaux, écharpes, lunettes)
2. **Nettoyage & profiling** — `pandas` : gestion des valeurs manquantes,
   doublons, harmonisation des devises (USD)
3. **Segmentation** — par quantiles *intra-catégorie* (Accessible / Mid / Luxe) :
   chaque produit est comparé aux autres de sa catégorie, pas au marché entier
4. **Analyse** — remise moyenne pondérée (SUM des écarts / SUM des prix de référence),
   médiane vs moyenne, écarts par segment
5. **Restitution** — dashboard Looker Studio avec filtres interactifs

## Les insights

1. **Écart de prix d'un facteur ~20** entre l'accessible et le luxe pour un même
   type de produit : le marché n'est pas un continuum, il est nettement segmenté.
2. **La remise est inversement liée au prix** : les marques premium protègent
   leur prix (remise faible), les marques accessibles utilisent la remise comme
   levier commercial. Le luxe ne se brade pas.
3. **Distribution asymétrique** : prix moyen 2 869 $ mais médiane bien inférieure
   — quelques pièces d'exception (montres) tirent la moyenne vers le haut.
   La médiane reflète mieux le produit typique.

## L'échantillon & les limites

- 6 catégories × 20 produits via recherche par mots-clés (API Channel3)
- Retailers principaux : Jomashop, Farfetch, TheRealReal
- Prix en USD après nettoyage
- **39 % des produits communiquent un prix de référence** — l'analyse des
  remises porte sur ce sous-ensemble (limite documentée)
- Snapshot ponctuel : pas de dimension temporelle (piste d'enrichissement)

## Stack technique

`Python` · `pandas` · `requests` · `Channel3 API` · `Looker Studio`

## Structure du repo

```
retail-price-gap-analysis/
├── notebooks/       # exploration et pipeline (Jupyter)
├── src/             # code d'extraction et transformation
├── data/            # données (non versionnées)
├── requirements.txt
└── README.md
```

## Reproduire

```bash
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
# ajouter sa clé Channel3 dans un fichier .env : CHANNEL3_API_KEY=...
```

---

*Analyse par Souleymane Ndiaye — Août 2026*
