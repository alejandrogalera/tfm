#!/bin/bash
cd ../data/ign
cat lineas_limite.tar.gz.a* > lineas_limite.tar.gz
tar zxvf lineas_limite.tar.gz 
rm lineas_limite.tar.gz
