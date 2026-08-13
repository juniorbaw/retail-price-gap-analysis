-- Verrouille la table des segments sur les valeurs de reference.
--
-- Ces quatre lignes sont citees dans les README, dans le catalogue de donnees
-- et dans les supports de candidature. Elles dependent de la METHODE de
-- decoupage autant que des donnees : un passage de qcut (bornes de valeur) a
-- ntile (effectifs egaux) laisse le CA total inchange a 430 952 USD, mais
-- deplace des clients entre segments et change le CA VIP de 221 653 a
-- 218 796 USD.
--
-- Aucun autre test ne verrait cette derive : les volumetries, la coherence du
-- CA et les parts a 100 % restent toutes vertes. C'est le seul garde-fou.
--
-- Tolerance : 1 USD sur le CA (arrondi), 0,1 point sur les parts.

with attendu as (

    select '4. VIP'         as segment_valeur, 42 as nb_clients, 221653 as ca_usd, 51.4 as pct_ca, 304.02 as panier_moyen
    union all
    select '3. Fidele'      as segment_valeur, 41 as nb_clients,  87279 as ca_usd, 20.3 as pct_ca, 110.68 as panier_moyen
    union all
    select '2. Regulier'    as segment_valeur, 41 as nb_clients,  70477 as ca_usd, 16.4 as pct_ca, 110.72 as panier_moyen
    union all
    select '1. Occasionnel' as segment_valeur, 42 as nb_clients,  51543 as ca_usd, 12.0 as pct_ca,  98.57 as panier_moyen

),

constate as (

    select
        segment_valeur,
        nb_clients,
        ca_segment_usd,
        pct_ca,
        panier_moyen_usd
    from {{ ref('mart_segments') }}

)

select
    attendu.segment_valeur,
    attendu.nb_clients      as nb_clients_attendu,
    constate.nb_clients     as nb_clients_constate,
    attendu.ca_usd          as ca_attendu,
    constate.ca_segment_usd as ca_constate,
    attendu.pct_ca          as pct_ca_attendu,
    constate.pct_ca         as pct_ca_constate

from attendu
join constate on attendu.segment_valeur = constate.segment_valeur
where attendu.nb_clients <> constate.nb_clients
   or abs(attendu.ca_usd - constate.ca_segment_usd) > 1
   or abs(attendu.pct_ca - constate.pct_ca) > 0.1
   or abs(attendu.panier_moyen - constate.panier_moyen_usd) > 0.01
