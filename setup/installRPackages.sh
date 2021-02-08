#!/bin/bash
sudo /usr/local/bin/R -e "install.packages(c('rgdal'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
sudo /usr/local/bin/R -e "install.packages(c('sp'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
sudo /usr/local/bin/R -e "install.packages(c('rgeos'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
sudo /usr/local/bin/R -e "install.packages(c('geojson'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
sudo /usr/local/bin/R -e "install.packages(c('maptools', 'tmap'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
sudo /usr/local/bin/R -e "install.packages(c('readxl', 'htmlwidgets', 'stringr'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
sudo /usr/local/bin/R -e "install.packages(c('leaflet', 'osrm'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
#sudo /usr/local/bin/R -e "install.packages(c('googleCloudStorageR', 'googleAuthR', 'googleAnalyticsR', 'searchConsoleR'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
