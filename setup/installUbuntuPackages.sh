#!/bin/bash
sudo apt-get update
sudo apt-get -y install locales
sudo locale-gen es_ES.UTF-8
sudo echo "LC_CTYPE=\"es_ES.UTF-8\""
sudo echo "LC_ALL=\"es_ES.UTF-8\""
sudo echo "LANG=\"es_ES.UTF-8\""
