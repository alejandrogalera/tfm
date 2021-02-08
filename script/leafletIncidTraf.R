
options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")


library(sp)       #Datos espaciales
library(rgdal)    #Lectura de cartografías
library(rgeos)    #Lectura de cartografías
library(maptools) #Lectura de cartografías
library(readxl)   #Lectura de ficheros Excel
library(tmap)     #Representación de funciones
library(stringr)  #Para str_split_fixed
library(leaflet)  #Mapas web interactivos.
library(htmlwidgets) #Guardar gráficos en html.

#Cargamos los datos procesados
load("data/r/catalunyaPoblacMap.RData")          #Para el mapa base.
load("data/r/paradasLineasNoDupMunicipio.RData") #Para un tipo de marcadores
#load("data/r/incidentesTrafico.RData")   #Para el otro tipo de marcadores: incidentes de tráfico.
load("data/r/fullData.RData")                    #Para el gasto medio en transporte por municipio.


#Primero leemos de data/r/
dir("script/")
incidTrafLatest <- read.csv("script/incid_traf_latest.csv")
incidTrafCatLatest <- incidTrafLatest[incidTrafLatest$autonomia=="CATALUÑA",]

colnames(incidTrafCatLatest)

######################
# incidTrafCatLatest #
######################
#A continuación, situamos los marcadores correspondientes a los incidentes de Cataluña.
#Añadimos como marcadores los puntos de una línea.

dat <- data.frame(Longitude = incidTrafCatLatest$px,
                  Latitude = incidTrafCatLatest$py)

htmlLeafletOSMIncidTraf <- leaflet(data=incidTrafCatLatest) %>%
  addTiles()%>%  
  addMarkers(lng=~px, 
             lat=~py,
             popup=~paste0("Causa: ", causa, "<br>",
                           "Nivel: ", nivel, "<br>",
                           "Provincia: ", provincia, "<br>",
                           "Municipio: ", poblacion, "<br>",
                           "Carretera: ", carretera, "<br>")
             )
htmlLeafletOSMIncidTraf
saveWidget(htmlLeafletOSMIncidTraf, file="web/maps/htmlLeafletOSMIncidTraf.html")


#Personalización de los iconos según el tipo.
#https://stackoverflow.com/questions/32940617/change-color-of-leaflet-marker

iconos <- iconList(otros = makeIcon("icon/otros.svg", iconWidth = 24, iconHeight =32),
                   busstop = makeIcon("icon/42561-bus-stop-icon.png", iconWidth = 24, iconHeight =32))
                   
htmlLeafletOSMIncidTraf <- leaflet(data=incidTrafCatLatest) %>%
  addTiles()%>%  
  addMarkers(lng=~px, 
             lat=~py,
             icon = iconos[1])) 
htmlLeafletOSMIncidTraf

