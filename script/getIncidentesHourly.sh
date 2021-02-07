#!/bin/bash
DATE=`date "+%Y%m%d-%H"`
#BASEDIR=/home/agalera/workspace/bigdata/00_TFM/tfm
BASEDIR=/home/agalera/tfm
BUCKETNAME=agaleratfm-bucket

#Ejecutamos el python que se descarga el geojson y lo transforma a csv
python3 ${BASEDIR}/script/geojson2csv.py https://opendata.arcgis.com/datasets/a64659151f0a42c69a38563e9d006c6b_0.geojson ${BASEDIR}/data/opendata_esri/incid_traf/incid_traf_${DATE}.csv

#Copiamos al bucket
gsutil cp ${BASEDIR}/data/opendata_esri/incid_traf/incid_traf_${DATE}.csv gs://${BUCKETNAME}/incid_traf/incid_traf_${DATE}.csv

#El siguiente comando evita que el disco del cluster dataproc se llene
mv ${BASEDIR}/data/opendata_esri/incid_traf/incid_traf_${DATE}.csv ${BASEDIR}/data/opendata_esri/incid_traf/incid_traf_latest.csv
#Copiamos el latest al bucket para que sea accesible por el script de PySpark
gsutil cp ${BASEDIR}/data/opendata_esri/incid_traf/incid_traf_latest.csv gs://${BUCKETNAME}/incid_traf/incid_traf_latest.csv

