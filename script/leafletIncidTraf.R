
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
incidTrafLatest <- read.csv("script/incid_traf_latest.csv", header = TRUE, sep = ',', encoding = 'utf-8')
incidTrafCatLatest <- incidTrafLatest[incidTrafLatest$autonomia=="CATALUÑA",]

colnames(incidTrafCatLatest)

#####################
# Creación icon set #
#####################
#https://stat.ethz.ch/R-manual/R-devel/library/base/html/trimws.html
all_causas <- unique(trimws(incidTrafLatest$causa, which = c("both"), whitespace = "[ \t\r\n]"))
all_causas[all_causas==""]<-"OTROS"
all_causas<-unique(all_causas)
all_causas

iconos <- iconList(niebla1 = makeIcon("icon/otros.svg", iconWidth = 24, iconHeight =32),
                   busstop = makeIcon("icon/42561-bus-stop-icon.png", iconWidth = 24, iconHeight =32))








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
unique(incidTrafCatLatest$causa)
data.01.niebla <- incidTrafCatLatest[incidTrafCatLatest$causa=="NIEBLA",]
data.02.nieve <- incidTrafCatLatest[incidTrafCatLatest$causa=="NIEVE",]
data.03.viento <- incidTrafCatLatest[incidTrafCatLatest$causa=="VIENTO",]
data.04.lluvia <- incidTrafCatLatest[incidTrafCatLatest$causa=="LLUVIA",]
data.05.hielo <- incidTrafCatLatest[incidTrafCatLatest$causa=="HIELO",]
data.06.cerrado <- incidTrafCatLatest[startsWith(as.character(incidTrafCatLatest$causa), "CERRADO"),]
data.07.accidente <- incidTrafCatLatest[incidTrafCatLatest$causa=="ACCIDENTE",]
data.08.congestion <- incidTrafCatLatest[incidTrafCatLatest$causa=="CONGESTION",]
data.09.mantenimiento <- incidTrafCatLatest[startsWith(as.character(incidTrafCatLatest$causa), "MANTENIMIENTO"),]
data.10.obras <- incidTrafCatLatest[incidTrafCatLatest$causa=="OBRAS EN GENERAL",]
data.11.otros <- incidTrafCatLatest[startsWith(as.character(incidTrafCatLatest$causa), "OTR"),]
data.12.itinerario_alternativo <- incidTrafCatLatest[incidTrafCatLatest$causa=="ITINERARIO ALTERNATIVO",]
                   
htmlLeafletOSMIncidTraf <- leaflet(data=data.10.obras) %>%
  addTiles()%>%  
  addMarkers(lng=~px, 
             lat=~py,
             icon = iconos[1])
htmlLeafletOSMIncidTraf
leaflet(data=data.11.otros) %>%
  addMarkers(lng=~px, 
             lat=~py,
             icon = iconos[2])
#htmlLeafletOSMIncidTraf

aa <- c(1, 2, 1, 3, 2, 1, 1, 3)
cut(mag)



######################
# Incidente re-route #
######################
#Vilafranca - El Vendrell -Tarragona -Port Aventura. Autocars del Penedés
paradasL0808 <- read.csv(file = "data/r/paradasL0808.csv", header = TRUE, encoding = "utf-8")
paradaJuliCesar <- paradasL0808[paradasL0808$FID==9166,]
paradaJuliCesar$Latitude
paradaJuliCesar$Longitude





head(incidTrafCatLatest)
# colnames((incidTrafLatest))


library(tidyverse)
head(quakes)
mutate(quakes, group = cut(mag, breaks = c(0, 5, 6, Inf), labels = c("blue", "green", "orange"))) -> mydf

### I edit this png file and created my own marker.
### https://raw.githubusercontent.com/lvoogdt/Leaflet.awesome-markers/master/dist/images/markers-soft.png
quakeIcons <- iconList(blue = makeIcon("icon/01.niebla.png", iconWidth = 24, iconHeight =32),
                       green = makeIcon("icon/06.cerrado.svg", iconWidth = 24, iconHeight =32),
                       orange = makeIcon("icon/11.otros.svg", iconWidth = 24, iconHeight =32))


leaflet(data = mydf[1:100,]) %>% 
  addTiles() %>%
  addMarkers(icon = ~quakeIcons[group])
