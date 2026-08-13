-- Grain : une ligne = une transaction. Volumetrie attendue : 2 750 lignes.
--
-- Le fichier source compte 3 400 lignes, dont 650 sans montant. Une ligne sans
-- montant n'est pas une transaction exploitable pour une analyse de chiffre
-- d'affaires : elle est ecartee ici, une bonne fois, et jamais reintroduite en
-- aval. C'est le seul endroit du projet ou cette regle s'applique.

with source as (

    select * from {{ ref('fashion_retail_sales') }}

),

nettoye as (

    select
        cast("Customer Reference ID" as integer)                as client_id,
        trim("Item Purchased")                                  as article,
        cast("Purchase Amount (USD)" as double)                 as montant_usd,
        -- Source en JJ-MM-AAAA : le format est explicite pour eviter toute
        -- interpretation ambigue entre jour et mois.
        cast(strptime("Date Purchase", '%d-%m-%Y') as date)      as date_achat,
        cast("Review Rating" as double)                         as note_avis,
        trim("Payment Method")                                  as mode_paiement

    from source
    where "Purchase Amount (USD)" is not null

)

select
    -- La source n'a pas d'identifiant de transaction. On en fabrique un,
    -- deterministe : l'ordre porte sur toutes les colonnes metier, et le
    -- fichier ne contient aucune ligne strictement dupliquee (verifie), donc
    -- le meme CSV produit toujours les memes identifiants.
    row_number() over (
        order by client_id, date_achat, article, montant_usd, mode_paiement, note_avis
    )                                                           as transaction_id,
    client_id,
    article,
    montant_usd,
    date_achat,
    note_avis,
    mode_paiement

from nettoye
