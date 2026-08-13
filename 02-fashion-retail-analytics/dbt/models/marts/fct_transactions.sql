-- Grain : une ligne = une transaction. 2 750 lignes.
--
-- Table de faits du schema en etoile. Elle ne porte QUE :
--   - sa cle primaire (transaction_key)
--   - les cles etrangeres vers les dimensions (client, article, date)
--   - les mesures additives au grain transaction (montant_usd)
--   - une mesure semi-additive (note_avis, qui ne se somme pas mais se moyenne)
--
-- Ce qu'elle ne porte PAS, deliberement : aucun agregat client (ca_client,
-- nb_transactions). C'est exactement ce que faisait l'export initial, et c'est
-- ce qui produisait le fan-out. Un agregat client vit dans dim_clients, et
-- Power BI le retrouve par la relation, sans jamais le dupliquer.

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

articles as (

    select article_key, article_nom from {{ ref('dim_articles') }}

)

select
    transactions.transaction_id                     as transaction_key,

    -- Cles etrangeres
    transactions.client_id                          as client_key,
    articles.article_key,
    cast(strftime(transactions.date_achat, '%Y%m%d') as integer) as date_key,

    -- Mesures
    transactions.montant_usd,
    transactions.note_avis,

    -- Attribut degenere : le mode de paiement est un attribut de la
    -- transaction elle-meme, pas d'une entite externe. Lui creer une dimension
    -- a deux lignes n'apporterait rien.
    transactions.mode_paiement,

    transactions.date_achat

from transactions
inner join articles
    on transactions.article = articles.article_nom
