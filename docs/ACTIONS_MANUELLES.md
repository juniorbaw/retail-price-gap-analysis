# Actions manuelles restantes

Ces actions demandent un acces aux reglages GitHub ou a une machine locale.
Rien n'a ete execute sans accord : **aucun depot autre que
`retail-price-gap-analysis` n'a ete modifie**.

---

## 1. Fusionner la branche de travail

Tout le travail est sur `claude/portfolio-repo-cleanup-hazcy6`. La branche
`main` porte encore l'ancienne version.

```bash
git checkout main
git merge claude/portfolio-repo-cleanup-hazcy6
git push origin main
```

Ou via une pull request, si tu preferes relire le diff dans l'interface.

## 2. Description et topics du depot

En ligne de commande (necessite `gh` authentifie) :

```bash
gh repo edit juniorbaw/retail-price-gap-analysis \
  --description "Portfolio data analytics — modele dimensionnel dbt teste, retail & luxe" \
  --add-topic sql \
  --add-topic dbt \
  --add-topic analytics-engineering \
  --add-topic data-quality \
  --add-topic retail \
  --add-topic luxury \
  --add-topic duckdb \
  --add-topic power-bi
```

Sinon : page du depot, engrenage a droite de « About ».

## 3. Epingler le depot sur le profil

Interface uniquement (aucune API publique) :

1. Aller sur https://github.com/juniorbaw
2. **Customize your pins**
3. Cocher `retail-price-gap-analysis`, decocher le reste
4. **Save pins**

## 4. Publier le catalogue dbt sur GitHub Pages

Le catalogue est deja genere a chaque build de la CI et telechargeable en
artefact. Pour l'heberger :

```bash
make docs
mkdir -p docs-site
cp 02-fashion-retail-analytics/dbt/target/index.html \
   02-fashion-retail-analytics/dbt/target/manifest.json \
   02-fashion-retail-analytics/dbt/target/catalog.json \
   docs-site/
git add docs-site
git commit -m "docs: publish dbt catalog"
git push
```

Puis **Settings > Pages > Source: Deploy from a branch**, branche `main`,
dossier `/docs-site`.

**A savoir avant de committer** : ces artefacts sont volumineux —
`index.html` fait **1,8 Mo** et `manifest.json` **1,1 Mo**. Les versionner
introduit deux fichiers de plus de 1 Mo dans un depot qui n'en contient
aujourd'hui aucun, et ils changent a chaque build.

Deux facons d'eviter cela :

- **Preferee** : publier via GitHub Actions plutot que par commit, avec
  `actions/deploy-pages`. Le site est servi depuis un artefact, rien n'entre
  dans l'historique git. La CI genere deja le catalogue a chaque run.
- Sinon, accepter les 3 Mo dans l'historique, en sachant qu'ils grossiront a
  chaque regeneration.

Le lien sera `https://juniorbaw.github.io/retail-price-gap-analysis/`. Une fois
la page en ligne, remplacer la mention « a activer » en haut du
[README du projet 02](../02-fashion-retail-analytics/README.md) par le lien
reel.

## 5. Depots hors sujet — a decider

**Aucun de ces depots n'a ete touche.** Ils sont publics et visibles sur le
profil :

| Depot | Suggestion |
|---|---|
| `FitFlow` | Archiver ou passer en prive |
| `ProofPulse` | Archiver ou passer en prive |
| `Ndiaye-Family` | Deja prive — rien a faire |
| `Ndiaye-Family-1` | Archiver ou supprimer (doublon) |
| `Velocia`, `replai` | Archiver ou passer en prive |
| `autoecole-mortier`, `iram-international` | A ton appreciation |
| `data-portfolio` | Voir point 6 |

Passer en prive (reversible, le depot disparait du profil public) :

```bash
gh repo edit juniorbaw/FitFlow --visibility private --accept-visibility-change-consequences
```

Archiver (le depot reste visible mais devient lecture seule, avec un bandeau
« archived ») :

```bash
gh repo archive juniorbaw/FitFlow
```

**Recommandation** : passer en prive plutot qu'archiver. Un depot archive reste
compte dans les statistiques du profil et affiche toujours son langage principal ;
un depot prive disparait completement de la vue publique.

## 6. Que faire de `data-portfolio`

Ce depot contient l'ancienne version : **20 288 fichiers de `venv/` versionnes**,
un `.git` de **91 Mo** pour environ 700 Ko de contenu utile, un CV en clair, et
les chiffres faux (2 800 clients, CA 7,6 M€).

Il n'a pas ete modifie : cette session n'avait pas les droits d'ecriture dessus.

Trois options :

1. **Le passer en prive** (le plus simple) :
   `gh repo edit juniorbaw/data-portfolio --visibility private --accept-visibility-change-consequences`
2. **Le supprimer**, tout son contenu utile ayant ete repris ici — la source
   `Fashion_Retail_Sales.csv` est importee a l'octet pres (md5 verifie).
3. **Le remplacer** par le contenu de ce depot, si tu tiens au nom
   `data-portfolio`. Dans ce cas, renommer plutot ce depot-ci depuis les
   reglages, et supprimer l'ancien : cela evite de reintroduire les 91 Mo
   d'historique.

**Tant que ce depot reste public, le CV et les chiffres faux le sont aussi.**
C'est le point le plus urgent de cette liste.

## 7. Chiffres du projet 01 a revalider

Rejouer la collecte avec une cle Channel3, puis confronter :

```bash
cd 01-price-positioning-luxury
echo "CHANNEL3_API_KEY=ta_cle" > .env
python src/collecte.py  --sortie data/produits_bruts.csv
python src/nettoyage.py --entree data/produits_bruts.csv \
                        --sortie data/produits_clean.csv \
                        --kpi    data/kpi_verifies.csv
cat data/kpi_verifies.csv
```

Le fichier produit `prix_moyen_usd` et `prix_median_usd` cote a cote : c'est ce
qui tranche la contradiction sur les 2 869 USD (moyenne ou mediane selon les
versions). Mettre ensuite a jour le tableau
« Chiffres a verifier » du README du projet 01.

Une fois `produits_clean.csv` obtenu, le versionner : il pese quelques dizaines
de Ko et rend le projet reproductible en lecture, meme sans cle d'API.

## 8. Dashboards

Le README du projet 01 mentionnait un dashboard Looker Studio et une image
`dashboard.png` **qui n'existait pas dans le depot** (image cassee sur GitHub).
La reference a ete retiree.

A faire si tu veux remettre des visuels :

- Exporter des captures PNG des dashboards dans
  `02-fashion-retail-analytics/dashboard/` et `01-price-positioning-luxury/`
- Verifier que le lien Looker Studio est toujours actif et public avant de le
  remettre dans un README

## 9. PDF de candidature — non realisable dans cette session

L'etape 8 du brief demandait des PDF dans `~/Data/candidatures/hermes-vie-ny/`.
Cette session tourne dans un conteneur distant et ephemere : il n'y a ni ce
dossier, ni les fichiers sources.

Etat des sources :

| Fichier | Statut |
|---|---|
| CV FR (`cv_data_analyst.md`) | Existe, dans `data-portfolio` |
| CV EN | Introuvable |
| Lettre de motivation | Introuvable |

Le CV FR contient par ailleurs les chiffres faux corriges ici : **2 800 clients**
et **7,6 M€** doivent devenir **166 clients** et **430 952 USD** avant toute
conversion en PDF.

Pour generer les PDF en local, une fois les trois sources reunies :

```bash
pip install weasyprint
mkdir -p ~/Data/candidatures/hermes-vie-ny

pandoc cv_fr.md -o ~/Data/candidatures/hermes-vie-ny/NDIAYE_Souleymane_CV_Data_Analyst_FR.pdf \
  --pdf-engine=weasyprint -V mainfont="Liberation Serif" -V fontsize=11pt

# Verifier que le PDF reste lisible par un ATS :
pdftotext -layout ~/Data/candidatures/hermes-vie-ny/NDIAYE_Souleymane_CV_Data_Analyst_FR.pdf -
```

Le texte extrait doit ressortir **dans l'ordre de lecture**, sans colonnes
melangees. Pas de tableaux, pas d'icones, pas de colonnes : un ATS lit le flux
texte, pas la mise en page.

Nommage demande :

- `NDIAYE_Souleymane_CV_Data_Analyst_FR.pdf`
- `NDIAYE_Souleymane_CV_Data_Analyst_EN.pdf`
- `NDIAYE_Souleymane_LM_Hermes_VIE.pdf`

**Numero de telephone** : aucun numero n'a ete trouve dans les depots (scan de
l'historique complet des deux depots). Il n'y a donc rien a retirer cote public.
Il reste a l'ajouter manuellement sur les PDF envoyes en candidature.
