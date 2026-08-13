-- Grain : une ligne = un article. Volumetrie attendue : 50.
--
-- La note moyenne est PONDEREE par le chiffre d'affaires, pas par le nombre
-- d'avis : une note portee par 8 000 USD de ventes pese davantage qu'une note
-- portee par 30 USD. Les lignes sans avis sont exclues du calcul de la note
-- (mais pas du CA), sinon un NULL contaminerait tout le numerateur.

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

agrege as (

    select
        article,
        count(*)                        as nb_transactions,
        count(distinct client_id)       as nb_clients,
        sum(montant_usd)                as ca_article_usd,
        avg(montant_usd)                as panier_moyen_usd,
        median(montant_usd)             as panier_median_usd,
        min(montant_usd)                as montant_min_usd,
        max(montant_usd)                as montant_max_usd,
        count(note_avis)                as nb_avis,
        avg(note_avis)                  as note_moyenne_simple,
        sum(case when note_avis is not null then montant_usd * note_avis end)
            / nullif(sum(case when note_avis is not null then montant_usd end), 0)
                                        as note_moyenne_ponderee

    from transactions
    group by article

)

select
    article,
    nb_transactions,
    nb_clients,
    ca_article_usd,
    panier_moyen_usd,
    panier_median_usd,
    montant_min_usd,
    montant_max_usd,
    nb_avis,
    note_moyenne_simple,
    note_moyenne_ponderee,
    100.0 * ca_article_usd / sum(ca_article_usd) over () as pct_ca,
    row_number() over (order by ca_article_usd desc)     as rang_ca

from agrege
order by ca_article_usd desc
