-- LE test qui aurait attrape le bug de grain.
--
-- Contexte : la version initiale du projet exportait un CSV ou la colonne
-- total_depense (CA du client, grain CLIENT) etait rapatriee sur chaque ligne
-- de transaction (grain TRANSACTION). Sommer cette colonne sur les 2 750
-- lignes multipliait le CA de chaque client par son nombre d'achats :
--
--     CA reel      :   430 952 USD
--     CA fan-out   : 7 585 581 USD   (= 430 952 x 17,60 achats/client)
--
-- Le chiffre errone (7,6 M) a ete publie sur le README et sur un CV.
--
-- Ce test compare la meme grandeur mesuree a deux grains differents. Ils
-- doivent tomber sur la valeur identique. Si un fan-out reapparait dans
-- dim_clients ou en amont, l'ecart explose et dbt echoue.
--
-- Tolerance : 0,01 USD, pour absorber l'ordre de sommation en virgule
-- flottante, pas une vraie divergence.

with ca_transactions as (

    select sum(montant_usd) as ca from {{ ref('stg_transactions') }}

),

ca_clients as (

    select sum(ca_client) as ca from {{ ref('dim_clients') }}

)

select
    ca_transactions.ca as ca_grain_transaction,
    ca_clients.ca      as ca_grain_client,
    abs(ca_transactions.ca - ca_clients.ca) as ecart_usd

from ca_transactions
cross join ca_clients
where abs(ca_transactions.ca - ca_clients.ca) > 0.01
