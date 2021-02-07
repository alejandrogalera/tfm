#rgdal 
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
#sudo add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/'
#sudo apt-get update
#sudo apt-get install r-base

R -e "install.packages(c('sp', 'rgdal'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

#'rgeos', 'maptools', 'readxl', 'tmap', 'stringr', 'htmlwidgets'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
#'leaflet', 'htmlwidgets', 'osrm'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
