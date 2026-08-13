# Rapport de controle final

Branche : `claude/portfolio-repo-cleanup-hazcy6`
Depot : `juniorbaw/retail-price-gap-analysis`
Date : 13 aout 2026

---

## Points de controle

### [x] `dbt build` vert, 2 750 transactions et 166 clients confirmes

```
Done. PASS=134 WARN=0 ERROR=0 SKIP=0 TOTAL=134
```

134 noeuds : 1 seed, 8 modeles, 125 tests. Verifie apres un `make clean`
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

### [!] Aucun chiffre du repo en contradiction avec le BLOC 0

**Le BLOC 0 n'a jamais ete transmis.** Le controle a donc porte sur la source
de donnees elle-meme, qui est la seule reference verifiable.

Trois chiffres publies sont contredits par la source et ont ete corriges :

| Publie | Reel | Nature de l'erreur |
|---|---|---|
| CA 7,6 M€ | **430 952 USD** | Fan-out : `430 952 x 16,57` transactions par client |
| 2 800 clients | **166** | Sans origine identifiable dans le fichier |
| 8,9 % VIP = 54,1 % CA | **24,7 % VIP = 50,8 % CA** | Une segmentation par quartiles donne ~25 % par construction |

Le projet 01 n'a pas pu etre verifie : son CSV n'est pas versionne et l'API
exige une cle. Ses chiffres sont signales comme non reproductibles, dont une
contradiction directe entre deux versions sur les 2 869 USD (moyenne ou
mediane). Voir la section 7 de `ACTIONS_MANUELLES.md`.

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
3. **Revalider les chiffres du projet 01** en rejouant la collecte.

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

## Ce qui n'a pas ete fait, et pourquoi

- **Les PDF** : sources absentes, outils absents, conteneur ephemere.
- **GitHub Pages** : demande un acces aux reglages du depot.
- **Les depots tiers** (`FitFlow`, `ProofPulse`, `Ndiaye-Family`,
  `data-portfolio`, `juniorbaw/juniorbaw`) : aucun n'a ete touche, conformement
  a la consigne.
- **Les chiffres du projet 01** : non recalculables sans la source ni la cle
  d'API. Signales comme tels plutot que republies tels quels.

## Deux defauts trouves en verifiant

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
