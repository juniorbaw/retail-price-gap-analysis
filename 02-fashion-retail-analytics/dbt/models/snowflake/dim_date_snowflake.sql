-- Equivalent Snowflake de marts/dim_date.sql.
--
-- C'est le modele qui concentre le plus de differences de syntaxe : la
-- generation d'une serie de dates n'a rien de standard entre moteurs.

with bornes as (

    select
        min(date_achat) as date_min,
        max(date_achat) as date_max
    from {{ ref('stg_transactions_snowflake') }}

),

calendrier as (

    -- DuckDB   : unnest(generate_series(debut, fin, interval 1 day))
    -- Snowflake: TABLE(GENERATOR(ROWCOUNT => n)) + SEQ4() pour l'offset.
    -- GENERATOR exige un ROWCOUNT constant a la compilation : on genere donc
    -- large (2 ans) puis on coupe sur la borne haute.
    select
        DATEADD(
            day,
            SEQ4(),
            (select date_min from bornes)
        ) as date_jour
    from TABLE(GENERATOR(ROWCOUNT => 730))
    qualify date_jour <= (select date_max from bornes)

)

select
    -- DuckDB   : cast(strftime(d, '%Y%m%d') as integer)
    -- Snowflake: TO_NUMBER(TO_CHAR(d, 'YYYYMMDD')) -- masque SQL
    TO_NUMBER(TO_CHAR(date_jour, 'YYYYMMDD'))       as date_key,
    date_jour,
    YEAR(date_jour)                                 as annee,
    QUARTER(date_jour)                              as trimestre,
    MONTH(date_jour)                                as mois,
    -- Attention : MONTHNAME renvoie une abreviation ('Oct') chez Snowflake,
    -- la ou monthname() de DuckDB renvoie le nom complet ('October').
    MONTHNAME(date_jour)                            as mois_nom,
    DAY(date_jour)                                  as jour,
    WEEKISO(date_jour)                              as semaine_iso,
    DAYOFWEEKISO(date_jour)                         as jour_semaine_num,
    -- Idem : DAYNAME renvoie 'Mon' chez Snowflake, 'Monday' chez DuckDB.
    DAYNAME(date_jour)                              as jour_semaine_nom,
    case when DAYOFWEEKISO(date_jour) >= 6
         then TRUE else FALSE end                   as est_weekend,
    TO_CHAR(date_jour, 'YYYY-MM')                   as annee_mois,
    TO_CHAR(YEAR(date_jour)) || '-T' || TO_CHAR(QUARTER(date_jour))
                                                    as annee_trimestre,
    DATE_TRUNC('month', date_jour)                  as debut_mois,
    -- DATE_TRUNC('week') depend du parametre de session WEEK_START.
    -- Le forcer a 1 (lundi) pour s'aligner sur le comportement ISO de DuckDB.
    DATE_TRUNC('week', date_jour)                   as debut_semaine

from calendrier
order by date_jour
