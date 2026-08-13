-- Grain : une ligne = un jour. Couvre l'integralite de la plage observee dans
-- les transactions, sans trou.
--
-- Pourquoi une table de dates plutot que les fonctions de date a la volee :
-- une dimension date permet de filtrer sur des jours SANS vente (un jour a
-- zero euro existe dans la table, donc il apparait dans un graphique de serie
-- temporelle au lieu d'etre saute). C'est aussi ce que Power BI attend pour
-- activer sa "time intelligence" (cumuls, comparaisons M-1).

with bornes as (

    select
        min(date_achat) as date_min,
        max(date_achat) as date_max
    from {{ ref('stg_transactions') }}

),

calendrier as (

    -- generate_series est specifique a DuckDB. L'equivalent Snowflake figure
    -- dans models/snowflake/dim_date_snowflake.sql.
    select unnest(generate_series(
        (select date_min from bornes),
        (select date_max from bornes),
        interval 1 day
    ))::date as date_jour

)

select
    -- Cle de substitution au format AAAAMMJJ : lisible a l'oeil, triable, et
    -- c'est la convention attendue par Power BI pour une dimension date.
    cast(strftime(date_jour, '%Y%m%d') as integer)   as date_key,
    date_jour,
    extract(year    from date_jour)                  as annee,
    extract(quarter from date_jour)                  as trimestre,
    extract(month   from date_jour)                  as mois,
    monthname(date_jour)                             as mois_nom,
    extract(day     from date_jour)                  as jour,
    extract(week    from date_jour)                  as semaine_iso,
    -- ISO : 1 = lundi ... 7 = dimanche.
    extract(isodow  from date_jour)                  as jour_semaine_num,
    dayname(date_jour)                               as jour_semaine_nom,
    case when extract(isodow from date_jour) >= 6
         then true else false end                    as est_weekend,
    strftime(date_jour, '%Y-%m')                     as annee_mois,
    cast(extract(year from date_jour) as varchar)
        || '-T' || cast(extract(quarter from date_jour) as varchar)
                                                     as annee_trimestre,
    date_trunc('month', date_jour)::date             as debut_mois,
    date_trunc('week',  date_jour)::date             as debut_semaine

from calendrier
order by date_jour
