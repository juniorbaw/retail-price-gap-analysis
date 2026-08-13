-- Grain : une seule ligne. C'est la table de reference des chiffres publies
-- dans les README. Tout chiffre du portfolio doit sortir d'ici.
--
-- Les agregats sont calcules depuis stg_transactions (grain transaction) pour
-- le CA et le panier, et depuis dim_clients (grain client) pour le comptage de
-- clients. Chaque metrique est prise a son grain naturel : c'est exactement ce
-- que le bug initial ne faisait pas.

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

clients as (

    select * from {{ ref('dim_clients') }}

),

kpi_transactions as (

    select
        count(*)                                as nb_transactions,
        sum(montant_usd)                        as ca_total_usd,
        avg(montant_usd)                        as panier_moyen_usd,
        median(montant_usd)                     as panier_median_usd,
        min(montant_usd)                        as montant_min_usd,
        max(montant_usd)                        as montant_max_usd,
        min(date_achat)                         as date_debut,
        max(date_achat)                         as date_fin,
        count(note_avis)                        as nb_avis,
        avg(note_avis)                          as note_moyenne,
        count(distinct article)                 as nb_articles_distincts

    from transactions

),

kpi_clients as (

    select
        count(*)                                as nb_clients,
        avg(nb_transactions)                    as transactions_par_client

    from clients

)

select
    kpi_clients.nb_clients,
    kpi_transactions.nb_transactions,
    kpi_transactions.ca_total_usd,
    kpi_transactions.panier_moyen_usd,
    kpi_transactions.panier_median_usd,
    kpi_transactions.montant_min_usd,
    kpi_transactions.montant_max_usd,
    kpi_clients.transactions_par_client,
    kpi_transactions.nb_articles_distincts,
    kpi_transactions.nb_avis,
    kpi_transactions.note_moyenne,
    kpi_transactions.date_debut,
    kpi_transactions.date_fin

from kpi_transactions
cross join kpi_clients
