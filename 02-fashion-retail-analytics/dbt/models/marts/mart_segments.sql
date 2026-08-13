-- Grain : une ligne = un segment de valeur client. Volumetrie attendue : 4.
--
-- Construit exclusivement depuis dim_clients, donc au grain client. ca_segment
-- est une somme de ca_client : legitime ici, puisque chaque client n'apparait
-- qu'une fois dans la table source.

with clients as (

    select * from {{ ref('dim_clients') }}

),

agrege as (

    select
        segment_valeur,
        count(*)                    as nb_clients,
        sum(ca_client)              as ca_segment_usd,
        avg(ca_client)              as ca_moyen_par_client,
        avg(nb_transactions)        as transactions_par_client,
        avg(panier_moyen_client)    as panier_moyen_usd,
        min(ca_client)              as ca_client_min,
        max(ca_client)              as ca_client_max

    from clients
    group by segment_valeur

)

select
    segment_valeur,
    nb_clients,
    ca_segment_usd,
    ca_moyen_par_client,
    transactions_par_client,
    panier_moyen_usd,
    ca_client_min,
    ca_client_max,
    -- Parts calculees sur le total de la table via une fenetre sans partition :
    -- la somme des pourcentages vaut donc 100 par construction. Le test
    -- assert_parts_segments verifie que cette propriete tient reellement.
    100.0 * nb_clients      / sum(nb_clients)      over ()  as pct_clients,
    100.0 * ca_segment_usd  / sum(ca_segment_usd)  over ()  as pct_ca

from agrege
order by segment_valeur
