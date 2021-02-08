#!/bin/bash
#System packages
sudo apt-get update
sudo apt-get -y install locales
sudo locale-gen es_ES.UTF-8
sudo echo "LC_CTYPE=\"es_ES.UTF-8\""
sudo echo "LC_ALL=\"es_ES.UTF-8\""
sudo echo "LANG=\"es_ES.UTF-8\""

#Ubuntu libraries for python
sudo apt-get install -y python3-magic
sudo pip3 install spark

#Ubuntu libraries for R
sudo apt-get install -y libgdal-dev libfontconfig1-dev libcairo2-dev libudunits2-dev cargo libprotobuf-dev libjq-dev libv8-dev libavfilter-dev
sudo apt-get install -y r-base-dev r-base-core libjq-dev libcurl4-openssl-dev libssl-dev libprotobuf-dev libjq-dev libv8-3.14-dev protobuf-compiler #for geojson



#Web
sudo apt-get install -y apache2
