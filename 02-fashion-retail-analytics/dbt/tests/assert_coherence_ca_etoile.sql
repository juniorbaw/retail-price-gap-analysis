-- Meme garantie qu'assert_coherence_ca, mais appliquee au schema en etoile.
--
-- fct_transactions est construite en joignant stg_transactions a dim_articles.
-- Toute jointure est une occasion de fan-out : si dim_articles contenait un
-- jour deux lignes pour le meme libelle d'article, la table de faits
-- gagnerait des lignes et le CA gonflerait, silencieusement.
--
-- Le test unique sur article_nom couvre deja ce cas en amont. Celui-ci verifie
-- la consequence plutot que la cause : le CA de la table de faits doit rester
-- rigoureusement egal au CA du staging. C'est la verification qui survit meme
-- si quelqu'un desactive le test d'unicite.

with ca_staging as (

    select sum(montant_usd) as ca from {{ ref('stg_transactions') }}

),

ca_etoile as (

    select sum(montant_usd) as ca from {{ ref('fct_transactions') }}

)

select
    ca_staging.ca   as ca_staging,
    ca_etoile.ca    as ca_etoile,
    abs(ca_staging.ca - ca_etoile.ca) as ecart_usd

from ca_staging
cross join ca_etoile
where abs(ca_staging.ca - ca_etoile.ca) > 0.01
