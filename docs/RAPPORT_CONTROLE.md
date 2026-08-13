# Rapport de controle final

Branche : `claude/portfolio-repo-cleanup-hazcy6`
Depot : `juniorbaw/retail-price-gap-analysis`
Date : 13 aout 2026

---

## Points de controle

### [x] `dbt build` vert, 2 750 transactions et 166 clients confirmes

```
Done. PASS=135 WARN=0 ERROR=0 SKIP=0 TOTAL=135
```

135 noeuds : 1 seed, 8 modeles, 126 tests. Verifie apres un `make clean`
complet, donc depuis un arbre vierge.

| Attendu | Constate | Statut |
|---|---|---|
| 2 750 transactions | 2 750 | OK |
| 166 clients | 166 | OK |

Coherence du CA aux trois grains :

```
staging (transaction) : 430 952,00 USD
clients   (client)    : 430 952,00 USD
faits     (etoile)    : 430 952,00 USD
```

Controle arithmetique : `2 750 x 156,709818 = 430 952,00`, ecart `0,00000000`.

### [x] Aucun chiffre du repo en contradiction avec le BLOC 0

Le BLOC 0 a ete recu apres la premiere livraison. **Reconciliation complete,
chiffre par chiffre.**

Projet A — tous conformes :

| BLOC 0 | Constate | |
|---|---|---|
| 2 750 transactions | 2 750 | OK |
| 166 clients | 166 | OK |
| CA 430 952 USD | 430 952,00 | OK |
| Panier moyen 156,71 | 156,71 | OK |
| Panier median 110,00 | 110,00 | OK |
| Achats/client 6 / 28 / 16,6 | 6 / 28 / 16,57 | OK |
| 650 lignes sans montant (19,1 %) | 650 | OK |
| 324 notes manquantes (9,5 %) | 324 | OK |
| 50 articles, periode 2022-10-02 → 2023-10-01 | idem | OK |
| Top articles : Tunic 17 275 ... Poncho 11 422 | les 8 identiques | OK |
| Alertes note < 2,70 : Tunic 2,54 ... Sunglasses 2,67 | les 5 identiques | OK |
| Credit Card 53,5 % / 160,4 — Cash 46,5 % / 152,7 | idem | OK |

**Une divergence trouvee, sur la table des segments.** Ma premiere version
utilisait `ntile(4)` (effectifs egaux) la ou le BLOC 0 vient de `pd.qcut`
(bornes de valeur). Le CA total etait identique a 430 952 USD dans les deux cas,
et tous les tests existants restaient verts — mais la repartition differait :

| | Clients VIP | CA VIP | % CA VIP |
|---|---|---|---|
| `ntile`, ma version | 41 | 218 796 | 50,8 % |
| `qcut`, BLOC 0 | 42 | **221 653** | **51,4 %** |

`dim_clients` a ete bascule sur le decoupage par bornes de valeur. Les quatre
lignes correspondent maintenant exactement au BLOC 0, et un nouveau test,
`assert_segments_reference`, les verrouille — effectif, CA, part et panier
moyen. C'est le seul garde-fou contre un changement de methode qui laisse tous
les totaux justes.

Projet B — le BLOC 0 fournit les chiffres qui manquaient. Le README du projet 01
a ete reecrit dessus : 119 produits, 55 avec prix barre (46 %), prix median
376 USD, prix moyen 2 724,5 USD, remise simple 39,4 % et ponderee 23,3 %,
Spearman -0,58, gradient de remise 42,3 / 36,5 / 19,9 %, ratio des medianes
Luxe/Accessible 13,6.

Corrections apportees par rapport a ce qui etait publie :

| Publie | Reel |
|---|---|
| CA 7,6 M€ | **430 952 USD** (fan-out : x 16,57 achats/client) |
| 2 800 clients | **166** — c'etait 2 750 transactions arrondi a 2,8 k |
| 8,9 % VIP = 54,1 % CA | **25,3 % VIP = 51,4 % CA** |
| 120 produits | **119** |
| « prix median » 2 869 USD | **median 376**, moyenne 2 724,5 — faux label ET moyenne de moyennes |
| Remise ponderee 25,26 % | **23,3 %** |
| Ecart de prix facteur ~20 | **13,6** |

### [x] Aucun fichier > 1 Mo versionne inutilement, venv absent de l'historique

| Controle | Resultat |
|---|---|
| Fichiers > 1 Mo dans l'arbre | **0** |
| Blobs > 1 Mo dans l'historique | **0** |
| Fichiers `venv/` dans l'historique | **0** |
| Taille de `.git` | **1,4 Mo** |

Plus gros fichier versionne : `fct_transactions.csv`, 135 Ko.

Aucune purge d'historique n'a ete necessaire : `retail-price-gap-analysis`
n'a jamais contenu de `venv/`. C'est `data-portfolio` qui en portait 20 288
fichiers dans ses trois commits, et ce depot n'a pas ete modifie.

### [x] Aucun secret ni donnee personnelle dans le depot public

Scan de l'arbre **et de l'integralite de l'historique** (tous les blobs) :

| Recherche | Occurrences |
|---|---|
| Cles d'API, tokens, cles privees | **0** |
| Numeros de telephone | **0** |
| Adresses postales | **0** |
| Fichier `.env` versionne | **0** |
| CV ou lettre versionnes | **0** |
| Adresses email | 1 : `soujunior94@gmail.com` (contact volontaire) |

La sortie de notebook qui revelait la longueur de la cle d'API (`Longueur de la
cle : 40`) a ete supprimee.

Le `profiles.yml` versionne cible DuckDB en local et ne contient aucun
identifiant. Le profil Snowflake d'exemple passe par `env_var()`.

### [~] Tous les liens des README testes

Liens relatifs : **0 casse** sur 7 fichiers de documentation.

Liens HTTP : **non verifiables depuis ce conteneur.** Le proxy de la session
refuse la plupart des hotes par politique (`403` sur CONNECT), y compris
`img.shields.io`, `linkedin.com` et `github.io`. Ce ne sont donc pas des liens
casses, mais des liens non testes.

| Lien | Code | Lecture |
|---|---|---|
| `github.com/juniorbaw/retail-price-gap-analysis` | 200 | OK |
| `github.com/juniorbaw` | 403 | Bloque par le proxy |
| Badge CI, badge licence | 403 / 000 | Bloques par le proxy |
| `linkedin.com/in/souleymane-nd` | 000 | Bloque par le proxy |
| `juniorbaw.github.io/...` | 000 | Pages pas encore activee |

**A retester depuis ta machine.** Un lien avait bien un vrai defaut : il
pointait vers `blob/main/...`, chemin qui n'existera qu'apres la fusion de la
branche. Il a ete remplace par un lien relatif.

### [x] CI verte

Run 1 : **success**, 10 etapes sur 10, en 47 secondes.
Run 2 : **success**, 10 etapes sur 10, en 53 secondes (apres le correctif Makefile).

Etapes : checkout, Python 3.11, dependances, `dbt deps`, **controle md5 de la
source**, `dbt build`, `dbt docs generate`, publication du catalogue en
artefact, resume.

Le controle md5 arrete le run si `Fashion_Retail_Sales.csv` change, avant meme
de construire les modeles.

### [ ] PDF generes et parsables par pdftotext

**Non realisable dans cette session.** Cette session tourne dans un conteneur
distant et ephemere : `~/Data/candidatures/hermes-vie-ny/` n'existe pas, et les
fichiers sources ne sont pas la.

| Source | Statut |
|---|---|
| CV FR | Existe, dans `data-portfolio` (non modifie) |
| CV EN | **Introuvable** |
| Lettre de motivation | **Introuvable** |

Ni `pandoc`, ni LaTeX, ni `weasyprint`, ni `pdftotext` ne sont installes.

Les commandes de generation et de verification ATS sont fournies en section 9
d'`ACTIONS_MANUELLES.md`. **Point important** : le CV FR actuel contient les
chiffres faux corriges ici (2 800 clients, 7,6 M€). Ils doivent devenir 166
clients et 430 952 USD avant toute conversion.

### [x] Liste des actions manuelles restantes

Neuf actions dans [`ACTIONS_MANUELLES.md`](ACTIONS_MANUELLES.md). Les trois
prioritaires :

1. **Fusionner la branche dans `main`** — tout le travail y est.
2. **Passer `data-portfolio` en prive ou le supprimer** — il expose encore
   publiquement le CV et les chiffres faux.
3. **Versionner `produits_clean.csv`** pour rendre le projet 01 reproductible
   en lecture, comme le projet 02.

---

## Etat par etape du brief

| Etape | Statut |
|---|---|
| 0 — Inventaire | Fait, avec trois blocages remontes avant toute ecriture |
| 1 — Hygiene git | Fait. Purge d'historique sans objet dans ce depot |
| 2 — Restructuration | Fait |
| 3 — Vrai projet dbt | Fait. `dbt build` vert, volumetries confirmees |
| 4 — Portabilite Snowflake + Power BI | Fait |
| 5 — Documentation | Fait |
| 6 — CI | Fait, verte |
| 7 — Profil GitHub | Contenu prepare. Aucun depot tiers modifie |
| 8 — PDF de candidature | **Non realisable** dans ce conteneur |
| 9 — Controle final | Ce document |

Reconciliation avec le BLOC 0 effectuee apres coup : une divergence de methode
trouvee et corrigee, les chiffres du projet 01 integres.

## Ce qui n'a pas ete fait, et pourquoi

- **Les PDF** : sources absentes, outils absents, conteneur ephemere.
- **GitHub Pages** : demande un acces aux reglages du depot.
- **Les depots tiers** (`FitFlow`, `ProofPulse`, `Ndiaye-Family`,
  `data-portfolio`, `juniorbaw/juniorbaw`) : aucun n'a ete touche, conformement
  a la consigne.
- **Les chiffres du projet 01** : non recalculables sans la source ni la cle
  d'API. Signales comme tels plutot que republies tels quels.

## Trois defauts trouves en verifiant

Ces deux points ont ete trouves en executant les commandes documentees plutot
qu'en les supposant correctes.

1. **La source brute avait ete modifiee a l'import.** La regle
   `*.csv text eol=lf` du `.gitattributes` avait converti ses fins de ligne de
   CRLF vers LF, changeant son md5. Corrige par une exception `-text` sur
   `data/raw/`, et la source est de nouveau identique a l'octet pres
   (`68a05918d5982267fb5f7b250fb3f079`).

2. **`make clean && make build` echouait.** `dbt clean` supprime
   `dbt_packages`, et la cible `deps` ajoutee pour y remedier etait elle-meme
   cassee par une precedence shell : `test ... || cd dbt && dbt deps` se lit
   `(test || cd dbt) && dbt deps`, ce qui lancait `dbt deps` dans le mauvais
   dossier. Corrige, et le cycle complet a ete rejoue depuis un arbre vierge.

3. **Une reecriture fidele en apparence changeait les chiffres.** Traduire
   `pd.qcut` par `ntile(4)` semble neutre : meme nombre de segments, meme CA
   total, tous les tests verts. Le CA VIP passait pourtant de 221 653 a
   218 796 USD. Une equivalence supposee entre deux fonctions n'en est pas une
   tant qu'elle n'est pas verifiee sur les valeurs.
