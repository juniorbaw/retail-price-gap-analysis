# Portabilite DuckDB vers Snowflake

Le projet tourne sur DuckDB pour rester reproductible sans compte cloud. Les
modeles equivalents Snowflake vivent dans `dbt/models/snowflake/`, desactives
par defaut (`+enabled: false` dans `dbt_project.yml`).

Ce document liste les differences de syntaxe reellement rencontrees en portant
les modeles. Ce ne sont pas des differences theoriques : chacune a casse un
modele qui fonctionnait sur DuckDB.

---

## 1. Conversion de texte vers date

C'est la difference la plus piegeuse, parce qu'elle ne provoque pas d'erreur :
elle produit des dates fausses.

| | DuckDB | Snowflake |
|---|---|---|
| Fonction | `strptime(colonne, '%d-%m-%Y')` | `TO_DATE(colonne, 'DD-MM-YYYY')` |
| Famille de masque | `strftime` (style C) | masque SQL |

`%d-%m-%Y` et `DD-MM-YYYY` decrivent le meme format, mais dans deux langages de
masque differents. Passer `'%d-%m-%Y'` a `TO_DATE` sur Snowflake echoue ; passer
`'DD-MM-YYYY'` a `strptime` sur DuckDB echoue aussi.

Le risque reel est ailleurs : la source est en **JJ-MM-AAAA**. Si le format est
omis et qu'on laisse le moteur deviner, les 12 premiers jours de chaque mois
sont interpretes en MM-JJ-AAAA et les dates sont silencieusement fausses. D'ou
le choix de charger la colonne en `VARCHAR` dans le seed et de convertir
explicitement.

## 2. Casse des identifiants

Snowflake replie tout identifiant **non quote** en MAJUSCULES, et compare les
identifiants **quotes** de maniere sensible a la casse. DuckDB, lui, est
insensible a la casse par defaut.

Les colonnes de la source contiennent des espaces et des parentheses
(`"Purchase Amount (USD)"`), donc elles doivent etre quotees. Sur Snowflake,
leur casse doit alors correspondre **exactement** au fichier source :
`"purchase amount (usd)"` ne resout pas.

C'est aussi pour cela que `quote: true` est declare sur chaque colonne du seed
dans `seeds/schema.yml` : sans cela, dbt genere des tests non echappes et le
SQL ne compile pas.

## 3. Generation d'une serie de dates

Aucune portabilite possible : les deux moteurs n'ont rien en commun ici.

**DuckDB** — une fonction de serie, bornes incluses :

```sql
select unnest(generate_series(DATE '2022-10-02', DATE '2023-10-01', interval 1 day))
```

**Snowflake** — un generateur de lignes, puis un decalage calcule :

```sql
select DATEADD(day, SEQ4(), DATE '2022-10-02')
from TABLE(GENERATOR(ROWCOUNT => 730))
qualify date_jour <= DATE '2023-10-01'
```

Deux contraintes propres a Snowflake apparaissent :

- `GENERATOR(ROWCOUNT => n)` exige un `n` **constant a la compilation** : il est
  impossible de lui passer `DATEDIFF(...)` calcule depuis les donnees. On genere
  donc large, puis on coupe.
- Couper suppose de filtrer sur une colonne calculee dans le meme `SELECT`, ce
  que `WHERE` ne permet pas. D'ou `QUALIFY`, une clause **specifique a
  Snowflake** qui filtre apres calcul des fonctions de fenetre et des alias.

## 4. Fonctions de date : memes noms, resultats differents

Le piege le plus sournois, parce que le SQL compile des deux cotes et que seul
le contenu change.

| Fonction | DuckDB | Snowflake |
|---|---|---|
| `DAYNAME(date)` | `Monday` | `Mon` |
| `MONTHNAME(date)` | `October` | `Oct` |
| Jour de semaine ISO | `extract(isodow from d)` | `DAYOFWEEKISO(d)` |
| Semaine ISO | `extract(week from d)` | `WEEKISO(d)` |

Un `accepted_values` sur `jour_semaine_nom` cale sur `['Monday', ...]` passerait
au vert sur DuckDB et echouerait sur Snowflake, alors que les deux modeles sont
corrects. Le libelle doit etre normalise cote modele si les deux cibles doivent
produire un resultat identique.

### Bonus : `DATE_TRUNC('week', ...)` depend d'un parametre de session

Sur Snowflake, le debut de semaine est gouverne par le parametre de session
`WEEK_START`. Par defaut (`0`), il est aligne sur la convention ISO, mais un
compte configure a `7` (dimanche) decalerait tous les debuts de semaine, sans
erreur ni avertissement. Un resultat qui depend d'un parametre de session n'est
pas reproductible : il faut le fixer explicitement dans le profil ou dans un
hook `on-run-start`.

---

## Ce que change dbt dans cette histoire

Ces differences sont exactement ce que les **macros dbt** servent a absorber.
Une macro `{% raw %}{{ nom_du_jour('date_jour') }}{% endraw %}` qui teste
`target.type` renvoie le bon SQL par moteur, et les modeles restent uniques :

```sql
{% raw %}{% macro nom_du_jour(colonne) %}
  {%- if target.type == 'duckdb' -%}
    dayname({{ colonne }})
  {%- elif target.type == 'snowflake' -%}
    DECODE(DAYOFWEEKISO({{ colonne }}), 1,'Monday', 2,'Tuesday', 3,'Wednesday',
                                        4,'Thursday', 5,'Friday', 6,'Saturday',
                                        7,'Sunday')
  {%- endif -%}
{% endmacro %}{% endraw %}
```

Le dossier `models/snowflake/` retenu ici est volontairement plus explicite :
il montre les deux SQL cote a cote, ce qui se lit mieux qu'une macro quand
l'objectif est de comprendre les differences. En production, la macro est le
bon choix : un seul modele a maintenir.
