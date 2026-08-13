-- Grain : une ligne = un article. 50 lignes.
--
-- Dimension article du schema en etoile. Volontairement distincte de
-- mart_produits : mart_produits est une table d'ANALYSE (elle porte des
-- mesures pre-agregees, du CA, des rangs), alors que dim_articles est une
-- DIMENSION (uniquement des attributs descriptifs, pas de mesure).
--
-- Melanger les deux est une erreur classique de modelisation : une dimension
-- qui contient du CA oblige a la recalculer des qu'un filtre change, et
-- produit des doubles comptages quand on la croise avec la table de faits.

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

articles as (

    select
        article,
        -- Attributs stables, derives du comportement observe. Ils decrivent
        -- l'article, ils ne mesurent pas une performance.
        min(date_achat) as date_premiere_vente,
        max(date_achat) as date_derniere_vente,
        median(montant_usd) as prix_median_usd
    from transactions
    group by article

),

classe as (

    select
        *,
        -- Gamme de prix : terciles du prix median des articles. Attribut
        -- descriptif, calcule une fois, stable dans le temps.
        ntile(3) over (order by prix_median_usd) as tercile_prix
    from articles

)

select
    -- Cle de substitution : un entier stable derive du libelle trie, pour ne
    -- pas dependre du texte comme cle de jointure en aval.
    row_number() over (order by article)    as article_key,
    article                                 as article_nom,
    prix_median_usd,
    case tercile_prix
        when 1 then '1. Entree de gamme'
        when 2 then '2. Milieu de gamme'
        else        '3. Haut de gamme'
    end                                     as gamme_prix,
    date_premiere_vente,
    date_derniere_vente

from classe
order by article_nom
