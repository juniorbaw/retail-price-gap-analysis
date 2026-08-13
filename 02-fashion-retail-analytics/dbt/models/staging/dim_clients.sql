-- Grain : une ligne = un client. Volumetrie attendue : 166 lignes.
--
-- ATTENTION, c'est ici que se jouait le bug de grain du projet initial :
-- les agregats calcules dans ce modele (ca_client, nb_transactions) sont au
-- grain CLIENT. Les rapatrier sur la table des transactions puis sommer
-- ca_client multiplie le CA de chaque client par son nombre d'achats
-- (fan-out). Voir docs/rapport_qualite_donnees.md.
--
-- Regle : ca_client ne se somme QUE depuis cette table, jamais depuis une
-- table au grain transaction.

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

agrege as (

    select
        client_id,
        count(*)                        as nb_transactions,
        sum(montant_usd)                as ca_client,
        avg(montant_usd)                as panier_moyen_client,
        median(montant_usd)             as panier_median_client,
        min(montant_usd)                as montant_min_client,
        max(montant_usd)                as montant_max_client,
        min(date_achat)                 as date_premier_achat,
        max(date_achat)                 as date_dernier_achat,
        -- count() ignore les NULL : c'est bien le nombre d'avis deposes.
        count(note_avis)                as nb_avis,
        avg(note_avis)                  as note_moyenne_client

    from transactions
    group by client_id

),

segmente as (

    select
        *,
        -- Segmentation par quartiles de CA. ntile decoupe la population en 4
        -- groupes d'effectifs quasi egaux : c'est une segmentation RELATIVE,
        -- pas un seuil metier absolu. Sur 166 clients : 42/42/41/41.
        ntile(4) over (order by ca_client) as quartile_valeur

    from agrege

)

select
    client_id,
    nb_transactions,
    ca_client,
    panier_moyen_client,
    panier_median_client,
    montant_min_client,
    montant_max_client,
    date_premier_achat,
    date_dernier_achat,
    nb_avis,
    note_moyenne_client,
    quartile_valeur,
    case quartile_valeur
        when 4 then '4. VIP'
        when 3 then '3. Fidele'
        when 2 then '2. Regulier'
        else        '1. Occasionnel'
    end as segment_valeur

from segmente
