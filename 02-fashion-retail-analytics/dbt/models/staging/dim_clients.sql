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

    -- Segmentation par quartiles de CA, decoupee sur les BORNES DE VALEUR
    -- (equivalent de pandas qcut), et non sur des effectifs egaux (ntile).
    --
    -- La difference n'est pas cosmetique. ntile force des groupes de taille
    -- quasi egale (42/42/41/41) en deplacant des clients de part et d'autre
    -- d'une borne ; le decoupage par valeur respecte les seuils reels et donne
    -- 42/41/41/42. Sur ce jeu de donnees, les deux methodes attribuent un CA
    -- VIP different : 218 796 contre 221 653 USD. Les chiffres publies sont
    -- ceux du decoupage par valeur.
    --
    -- Intervalles fermes a droite : ]borne precedente, borne].
    -- Portabilite : quantile_cont est propre a DuckDB. Snowflake ecrit
    -- PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ca_client).
    select
        agrege.*,
        case
            when agrege.ca_client <= bornes.q25 then 1
            when agrege.ca_client <= bornes.q50 then 2
            when agrege.ca_client <= bornes.q75 then 3
            else 4
        end as quartile_valeur

    from agrege
    cross join (
        select
            quantile_cont(ca_client, 0.25) as q25,
            quantile_cont(ca_client, 0.50) as q50,
            quantile_cont(ca_client, 0.75) as q75
        from agrege
    ) as bornes

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
