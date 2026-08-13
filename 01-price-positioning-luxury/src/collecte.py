"""Collecte de produits mode et luxe via l'API Channel3.

Usage :
    python src/collecte.py --sortie data/produits_bruts.csv
    python src/collecte.py --requetes "leather handbag" "luxury watch" --sortie data/test.csv

La cle d'API est lue depuis la variable d'environnement CHANNEL3_API_KEY
(via un fichier .env a la racine du projet). Elle n'est jamais journalisee.
"""

from __future__ import annotations

import argparse
import csv
import os
import sys

from dotenv import load_dotenv

# Les 6 categories retenues pour couvrir le spectre mode / luxe.
REQUETES_PAR_DEFAUT = [
    "leather handbag",
    "leather shoes",
    "luxury watch",
    "wool coat",
    "silk scarf",
    "sunglasses",
]

COLONNES = [
    "id",
    "titre",
    "marque",
    "categorie",
    "prix",
    "prix_barre",
    "devise",
    "retailer",
    "url",
    "requete",
]


def charger_cle() -> str:
    """Recupere la cle d'API, en nettoyant les guillemets parasites."""
    load_dotenv()
    cle = os.getenv("CHANNEL3_API_KEY")
    if not cle:
        sys.exit(
            "CHANNEL3_API_KEY introuvable. Cree un fichier .env contenant :\n"
            "  CHANNEL3_API_KEY=votre_cle"
        )
    return cle.strip().strip('"').strip("'")


def extraire_infos(produit, requete: str) -> dict:
    """Aplatit un objet produit Channel3 en un dictionnaire a plat.

    Le prix est imbrique dans la premiere offre : produit.offers[0].price.price.
    Un produit sans offre n'a pas de prix exploitable, ses champs restent None.
    """
    marque = produit.brands[0].name if produit.brands else None
    categorie = produit.category.title if produit.category else None

    prix = prix_barre = devise = retailer = url = None
    if produit.offers:
        offre = produit.offers[0]
        prix = offre.price.price
        prix_barre = offre.price.compare_at_price
        devise = offre.price.currency
        retailer = offre.domain
        url = offre.url

    return {
        "id": produit.id,
        "titre": produit.title,
        "marque": marque,
        "categorie": categorie,
        "prix": prix,
        "prix_barre": prix_barre,
        "devise": devise,
        "retailer": retailer,
        "url": url,
        "requete": requete,
    }


def collecter(requetes: list[str]) -> list[dict]:
    from channel3_sdk import Channel3

    client = Channel3(api_key=charger_cle())
    resultats = []

    for requete in requetes:
        print(f"Recherche : {requete}...")
        page = client.products.search(query=requete)
        for produit in page.products:
            resultats.append(extraire_infos(produit, requete))
        print(f"  -> {len(page.products)} produits")

    return resultats


def main() -> None:
    parseur = argparse.ArgumentParser(description=__doc__)
    parseur.add_argument(
        "--requetes",
        nargs="+",
        default=REQUETES_PAR_DEFAUT,
        help="Requetes de recherche (defaut : les 6 categories du projet)",
    )
    parseur.add_argument(
        "--sortie",
        default="data/produits_bruts.csv",
        help="Chemin du CSV de sortie",
    )
    args = parseur.parse_args()

    lignes = collecter(args.requetes)

    os.makedirs(os.path.dirname(args.sortie) or ".", exist_ok=True)
    with open(args.sortie, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLONNES)
        writer.writeheader()
        writer.writerows(lignes)

    print(f"\n{len(lignes)} produits ecrits dans {args.sortie}")


if __name__ == "__main__":
    main()
