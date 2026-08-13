-- Coherence interne des KPI publies : nb_transactions x panier_moyen = ca_total.
--
-- Les trois chiffres sont affiches cote a cote dans les README. S'ils ne se
-- recomposent pas, c'est qu'ils ne sont pas calcules sur la meme population :
-- typiquement un CA sur 3 400 lignes et un panier moyen sur 2 750. C'est
-- precisement le genre d'incoherence qu'un lecteur attentif repere en dix
-- secondes sur un portfolio.
--
-- Tolerance : 0,01 USD (arrondi flottant).

with kpi as (

    select * from {{ ref('mart_kpi_global') }}

)

select
    nb_transactions,
    panier_moyen_usd,
    ca_total_usd,
    nb_transactions * panier_moyen_usd          as ca_recalcule,
    abs(nb_transactions * panier_moyen_usd - ca_total_usd) as ecart_usd

from kpi
where abs(nb_transactions * panier_moyen_usd - ca_total_usd) > 0.01
