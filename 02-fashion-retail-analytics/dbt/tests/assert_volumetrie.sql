-- Verrouille les volumetries publiees dans les README : 2 750 transactions et
-- 166 clients.
--
-- Ce ne sont pas des chiffres arbitraires : ils sont cites dans le README
-- racine, le README du projet et le CV. Les figer dans un test signifie qu'une
-- modification de la source ou d'un filtre en amont fait echouer le build au
-- lieu de rendre la documentation silencieusement fausse.
--
-- Si ce test casse, c'est une decision a prendre, pas un chiffre a ajuster :
-- soit la source a change et il faut mettre a jour la documentation, soit un
-- filtre a derape et il faut le corriger.

with attendu as (

    select 'stg_transactions' as modele, 2750 as nb_attendu
    union all
    select 'dim_clients'      as modele, 166  as nb_attendu

),

constate as (

    select 'stg_transactions' as modele, count(*) as nb_constate
    from {{ ref('stg_transactions') }}
    union all
    select 'dim_clients'      as modele, count(*) as nb_constate
    from {{ ref('dim_clients') }}

)

select
    attendu.modele,
    attendu.nb_attendu,
    constate.nb_constate

from attendu
join constate on attendu.modele = constate.modele
where attendu.nb_attendu <> constate.nb_constate
