# Commandes du projet Fashion Retail Analytics.
#
# Toutes les cibles s'executent depuis 02-fashion-retail-analytics/.
# dbt tourne dans dbt/ avec --profiles-dir . : le profil DuckDB est versionne,
# donc rien a configurer avant de lancer.

DBT_DIR := dbt
DBT     := cd $(DBT_DIR) && dbt

.DEFAULT_GOAL := help
.PHONY: help setup build test docs export kpi clean

help:  ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup:  ## Installe les dependances Python et les packages dbt
	pip install -r ../requirements.txt
	$(DBT) deps

build:  ## Charge le seed, construit les modeles et lance tous les tests
	$(DBT) build --profiles-dir .

test:  ## Lance uniquement les tests, sans reconstruire les modeles
	$(DBT) test --profiles-dir .

docs:  ## Genere le catalogue statique dans dbt/target/
	$(DBT) docs generate --profiles-dir .
	@echo "Catalogue genere. Servir en local avec :"
	@echo "  cd $(DBT_DIR) && dbt docs serve --profiles-dir ."

export:  ## Exporte les marts en CSV et Parquet dans data/processed/
	$(DBT) run-operation exporter_marts --profiles-dir .

kpi:  ## Affiche les chiffres de reference apres un build
	@cd $(DBT_DIR) && python3 -c "\
import duckdb; \
c = duckdb.connect('fashion_retail.duckdb'); \
print(c.execute('select * from main_marts.mart_kpi_global').fetchdf().T.to_string())"

clean:  ## Supprime les artefacts de build (base, target, packages)
	$(DBT) clean
	rm -f $(DBT_DIR)/fashion_retail.duckdb $(DBT_DIR)/fashion_retail.duckdb.wal
	rm -rf $(DBT_DIR)/logs
