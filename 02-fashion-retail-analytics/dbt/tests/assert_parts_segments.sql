-- Les parts de segments doivent totaliser 100 %.
--
-- Une part qui ne boucle pas a 100 signale soit un segment manquant (un client
-- non classe, un CASE sans ELSE), soit un client compte dans deux segments.
-- Les deux sont des defauts de segmentation qui fausseraient directement la
-- phrase "X % des clients generent Y % du CA".
--
-- Tolerance : 0,01 point, pour l'arrondi flottant.

with segments as (

    select * from {{ ref('mart_segments') }}

),

totaux as (

    select
        sum(pct_clients)    as total_pct_clients,
        sum(pct_ca)         as total_pct_ca
    from segments

)

select
    total_pct_clients,
    total_pct_ca

from totaux
where abs(total_pct_clients - 100) > 0.01
   or abs(total_pct_ca - 100) > 0.01
