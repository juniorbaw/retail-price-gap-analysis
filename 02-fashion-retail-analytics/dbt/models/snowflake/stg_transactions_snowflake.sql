-- Equivalent Snowflake de staging/stg_transactions.sql.
--
-- Desactive sur la cible DuckDB (dbt_project.yml : snowflake +enabled false).
-- Pour l'executer : basculer le profil sur la cible snowflake et passer
-- +enabled a true.
--
-- Differences de syntaxe rencontrees, detaillees dans docs/PORTABILITE.md :
--   1. Conversion de date : strptime -> TO_DATE avec un masque different
--   2. Identifiants entre guillemets : sensibles a la casse chez Snowflake
--   3. Cast : :: fonctionne, mais CAST explicite est plus portable

with source as (

    select * from {{ ref('fashion_retail_sales') }}

),

nettoye as (

    select
        -- Snowflake replie les identifiants non quotes en MAJUSCULES. Les
        -- colonnes de la source contiennent des espaces, donc elles sont
        -- quotees : leur casse doit alors correspondre EXACTEMENT au fichier.
        CAST("Customer Reference ID" AS NUMBER(38, 0))      as client_id,
        TRIM("Item Purchased")                              as article,
        CAST("Purchase Amount (USD)" AS FLOAT)              as montant_usd,
        -- DuckDB : strptime(x, '%d-%m-%Y')
        -- Snowflake : TO_DATE(x, 'DD-MM-YYYY') -- masque SQL, pas strftime
        TO_DATE("Date Purchase", 'DD-MM-YYYY')              as date_achat,
        CAST("Review Rating" AS FLOAT)                      as note_avis,
        TRIM("Payment Method")                              as mode_paiement

    from source
    where "Purchase Amount (USD)" is not null

)

select
    ROW_NUMBER() over (
        order by client_id, date_achat, article, montant_usd, mode_paiement, note_avis
    )                                                       as transaction_id,
    client_id,
    article,
    montant_usd,
    date_achat,
    note_avis,
    mode_paiement

from nettoye
