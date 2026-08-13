{#
  Exporte les tables du schema en etoile et les marts vers data/processed/,
  en CSV (lisible, versionnable, ouvrable partout) et en Parquet (typé,
  compressé, ce que lit un moteur analytique).

  Lancer avec :
      dbt run-operation exporter_marts --profiles-dir .

  Les deux formats sont produits depuis la MEME requete, donc ils ne peuvent
  pas diverger : c'est le point important pour un dashboard qui consomme l'un
  et un test qui verifie l'autre.
#}

{% macro exporter_marts(chemin='../data/processed') %}

  {% set tables = [
      'fct_transactions',
      'dim_clients',
      'dim_articles',
      'dim_date',
      'mart_kpi_global',
      'mart_segments',
      'mart_produits'
  ] %}

  {% for table in tables %}

    {% set relation = ref(table) %}

    {% set requete_csv %}
      copy (select * from {{ relation }})
      to '{{ chemin }}/{{ table }}.csv'
      (format csv, header true, delimiter ',')
    {% endset %}

    {% set requete_parquet %}
      copy (select * from {{ relation }})
      to '{{ chemin }}/{{ table }}.parquet'
      (format parquet, compression zstd)
    {% endset %}

    {% do run_query(requete_csv) %}
    {% do run_query(requete_parquet) %}
    {% do log("exporte : " ~ table ~ " (csv + parquet)", info=True) %}

  {% endfor %}

{% endmacro %}
