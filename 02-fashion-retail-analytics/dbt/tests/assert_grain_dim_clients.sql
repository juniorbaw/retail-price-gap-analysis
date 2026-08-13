-- Verifie que dim_clients est bien au grain client : une ligne, un client.
--
-- Le test unique sur client_id (dans schema.yml) attrape deja les doublons.
-- Celui-ci exprime la meme garantie sous la forme qui compte pour un modele
-- dimensionnel : COUNT(*) doit egaler COUNT(DISTINCT cle). Si un jour une
-- jointure est ajoutee dans dim_clients et duplique des lignes, ce test tombe
-- en meme temps que assert_coherence_ca, et le message est explicite.

select
    count(*)                    as nb_lignes,
    count(distinct client_id)   as nb_clients_distincts

from {{ ref('dim_clients') }}
having count(*) <> count(distinct client_id)
