"""Nettoyage, segmentation et calcul des KPI du projet positionnement prix.

Usage :
    python src/nettoyage.py --entree data/produits_bruts.csv \
        --sortie data/produits_clean.csv --kpi data/kpi_verifies.csv

Le script est deterministe : a partir du meme CSV brut, il reproduit exactement
les chiffres publies dans le README du projet.
"""

from __future__ import annotations

import argparse
import os

import pandas as pd

# Bornes de segmentation : terciles de prix, calcules DANS chaque categorie.
QUANTILE_BAS = 0.33
QUANTILE_HAUT = 0.66

DEVISE_RETENUE = "USD"


def nettoyer(df: pd.DataFrame) -> pd.DataFrame:
    """Applique les regles de nettoyage, dans un ordre qui se justifie.

    1. Un produit sans prix est inexploitable pour une analyse de prix.
    2. Les doublons d'id viennent d'un meme produit remonte par deux requetes.
    3. Melanger les devises fausserait toute comparaison de prix.
    """
    avant = len(df)
    df = df[df["prix"].notna()]
    df = df.drop_duplicates(subset=["id"])
    df = df[df["devise"] == DEVISE_RETENUE]
    print(f"Nettoyage : {avant} -> {len(df)} lignes")
    return df.copy()


def segmenter(df: pd.DataFrame, cle_categorie: str = "requete") -> pd.DataFrame:
    """Attribue un segment de prix a chaque produit, relativement a sa categorie.

    Comparer une echarpe a une montre au prix absolu n'a pas de sens : les
    terciles sont donc calcules a l'interieur de chaque categorie.
    """

    def _label_groupe(groupe: pd.DataFrame) -> pd.Series:
        bas = groupe["prix"].quantile(QUANTILE_BAS)
        haut = groupe["prix"].quantile(QUANTILE_HAUT)

        def _label(prix: float) -> str:
            if prix <= bas:
                return "1. Accessible"
            if prix <= haut:
                return "2. Mid"
            return "3. Luxe"

        return groupe["prix"].apply(_label)

    df["segment"] = (
        df.groupby(cle_categorie, group_keys=False)
        .apply(_label_groupe, include_groups=False)
        .reindex(df.index)
    )
    return df


def calculer_kpi(df: pd.DataFrame) -> pd.DataFrame:
    """Produit la table des KPI verifies, un indicateur par ligne.

    La remise moyenne est *ponderee* : SUM(ecarts) / SUM(prix de reference).
    Une moyenne simple des pourcentages de remise donnerait autant de poids a
    une echarpe a 40 USD qu'a une montre a 20 000 USD.
    """
    avec_reference = df[df["prix_barre"].notna() & (df["prix_barre"] > 0)]

    remise_ponderee = (
        (avec_reference["prix_barre"] - avec_reference["prix"]).sum()
        / avec_reference["prix_barre"].sum()
        * 100
    )

    kpi = [
        ("nb_produits", len(df)),
        ("nb_categories", df["requete"].nunique()),
        ("nb_marques", df["marque"].nunique()),
        ("prix_moyen_usd", round(df["prix"].mean(), 2)),
        ("prix_median_usd", round(df["prix"].median(), 2)),
        ("prix_min_usd", round(df["prix"].min(), 2)),
        ("prix_max_usd", round(df["prix"].max(), 2)),
        ("nb_avec_prix_reference", len(avec_reference)),
        ("pct_avec_prix_reference", round(len(avec_reference) / len(df) * 100, 1)),
        ("remise_moyenne_ponderee_pct", round(remise_ponderee, 2)),
    ]
    return pd.DataFrame(kpi, columns=["indicateur", "valeur"])


def main() -> None:
    parseur = argparse.ArgumentParser(description=__doc__)
    parseur.add_argument("--entree", default="data/produits_bruts.csv")
    parseur.add_argument("--sortie", default="data/produits_clean.csv")
    parseur.add_argument("--kpi", default="data/kpi_verifies.csv")
    args = parseur.parse_args()

    df = pd.read_csv(args.entree)
    df = nettoyer(df)
    df = segmenter(df)
    kpi = calculer_kpi(df)

    for chemin in (args.sortie, args.kpi):
        os.makedirs(os.path.dirname(chemin) or ".", exist_ok=True)

    df.to_csv(args.sortie, index=False)
    kpi.to_csv(args.kpi, index=False)

    print(f"\n{args.sortie} : {len(df)} lignes")
    print(f"{args.kpi} :")
    print(kpi.to_string(index=False))


if __name__ == "__main__":
    main()
