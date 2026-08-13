# Commandes du portfolio.
#
# Les cibles delegent au projet 02, qui porte le pipeline dbt. Le projet 01 est
# un pipeline de collecte via une API authentifiee : il n'est pas rejouable en
# CI et a ses propres commandes, documentees dans son README.

PROJET_DBT := 02-fashion-retail-analytics

.DEFAULT_GOAL := help
.PHONY: help setup deps build test docs export kpi clean

help:  ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup:  ## Installe les dependances Python et les packages dbt
	$(MAKE) -C $(PROJET_DBT) setup

deps:  ## Installe les packages dbt s'ils manquent
	$(MAKE) -C $(PROJET_DBT) deps

build:  ## Construit les modeles dbt et lance tous les tests
	$(MAKE) -C $(PROJET_DBT) build

test:  ## Lance uniquement les tests dbt
	$(MAKE) -C $(PROJET_DBT) test

docs:  ## Genere le catalogue dbt et le graphe de lineage
	$(MAKE) -C $(PROJET_DBT) docs

export:  ## Exporte les marts en CSV et Parquet
	$(MAKE) -C $(PROJET_DBT) export

kpi:  ## Affiche les chiffres de reference
	$(MAKE) -C $(PROJET_DBT) kpi

clean:  ## Supprime les artefacts de build
	$(MAKE) -C $(PROJET_DBT) clean
