#!/usr/bin/env Rscript
#Setup del sistema de codificación.
options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")

#Librerías
library(sp)       #Datos espaciales
library(rgdal)    #Lectura de cartografías
library(rgeos)    #Lectura de cartografías
library(maptools) #Lectura de cartografías
library(readxl)   #Lectura de ficheros Excel
library(tmap)     #Representación de funciones
library(stringr)  #Para str_split_fixed
library(leaflet)  #Mapas web interactivos.
library(htmlwidgets) #Guardar gráficos en html.

#Manejo de argumentos de entrada
WORKDIR <- '.'
args = commandArgs(trailingOnly = TRUE)
if (length(args)>0)
{
  cat("Setting working dir to ",args[1])
  WORKDIR <- args[1]
}
setwd(WORKDIR)


#Cargamos los datos procesados
load("data/r/catalunyaPoblacMap.RData")          #Para el mapa base.
load("data/r/paradasLineasNoDupMunicipio.RData") #Para un tipo de marcadores
#load("data/r/incidentesTrafico.RData")   #Para el otro tipo de marcadores: incidentes de tráfico.
load("data/r/fullData.RData")                    #Para el gasto medio en transporte por municipio.


#Primero leemos de data/r/
dir("script/")
incidTrafLatest <- read.csv("script/incid_traf_latest.csv", header = TRUE, sep = ',', encoding = 'utf-8')
incidTrafCatLatest <- incidTrafLatest[incidTrafLatest$autonomia=="CATALUÑA",]


#Depuramos los missings.
incidTrafCatLatest$causa2  <- lapply(incidTrafCatLatest$causa, trimws)
incidTrafCatLatest <- incidTrafCatLatest[incidTrafCatLatest$causa2!="",]
incidTrafCatLatest$causa <- unlist(incidTrafCatLatest$causa2)
incidTrafCatLatest$causa2 <- NULL


#Obtenemos los posibles valores para los combo-box (select html) de la web
getUniqueAndSave <- function(vect, filename) 
{  
  #Encoding(vect) <- "UTF-8"
  #vect <- vect[!is.na(vect)]
  aux <- paste( as.vector(trimws(unique(vect))), collapse='\n')
  cat(aux)
  Encoding(aux) <- "UTF-8"
  write(aux, filename)
  return(aux) 
}

colnames(incidTrafCatLatest)
getUniqueAndSave(incidTrafLatest$autonomia, "web/select/autonomia.txt")
getUniqueAndSave(incidTrafCatLatest$carretera, "web/select/carretera.txt")
getUniqueAndSave(incidTrafLatest$causa, "web/select/causa.txt")
getUniqueAndSave(incidTrafCatLatest$poblacion, "web/select/poblacion.txt")
getUniqueAndSave(incidTrafLatest$nivel, "web/select/nivel.txt")
getUniqueAndSave(incidTrafLatest$tipo, "web/select/tipo.txt")
#https://stackoverflow.com/questions/46031256/populating-a-dropdown-list-with-values-from-a-text-file




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

#Hay que realizar una agrupación semántica de todas las causas que se puedan representar con un mismo icono.
#Por ejemplo, "CERRADO TAL CAMINO" = "CERRADO" = "CARRETERA CORTADA EN ESTE SENTIDO".
#Del mismo modo, "OBRAS EN GENERAL" = "OBRAS" = "MANTENIMIENTO" = "REASFALTADO".
#Además, para hacer uso del iconList, es necesario que el grupo sobre el que se discrimina la representación 
#de los iconos sea de tipo string sin contener espacios.
#El nuevo campo recibirá el nombre de causa_group

#Incidentes de obras y vías cerradas
incidTrafCatLatest$causa_group[grepl("CERRAD", incidTrafCatLatest$causa)] <- "closed" 
incidTrafCatLatest$causa_group[grepl("CORTAD", incidTrafCatLatest$causa)] <- "closed" 
incidTrafCatLatest$causa_group[grepl("OBRA", incidTrafCatLatest$causa)]     <- "works" 
incidTrafCatLatest$causa_group[grepl("ASFALT", incidTrafCatLatest$causa)]   <- "works"
incidTrafCatLatest$causa_group[grepl("MANTENIM", incidTrafCatLatest$causa)] <- "maintenance"   


#Incidentes meteorológicos
incidTrafCatLatest$causa_group[grepl("NIEBLA", incidTrafCatLatest$causa)]   <- "fog"
incidTrafCatLatest$causa_group[grepl("NIEVE", incidTrafCatLatest$causa)]    <- "snow"
incidTrafCatLatest$causa_group[grepl("VIENTO", incidTrafCatLatest$causa)]   <- "wind"
incidTrafCatLatest$causa_group[grepl("LLUVIA", incidTrafCatLatest$causa)]   <- "rain"
incidTrafCatLatest$causa_group[grepl("HIELO", incidTrafCatLatest$causa)]    <- "ice"

#Accidentes y otros.
incidTrafCatLatest$causa_group[grepl("CONGESTION", incidTrafCatLatest$causa)]  <- "congestion"
incidTrafCatLatest$causa_group[grepl("ACCIDENTE", incidTrafCatLatest$causa)]   <- "accident"
incidTrafCatLatest$causa_group[grepl("OTRO", incidTrafCatLatest$causa)]   <- "other"
incidTrafCatLatest$causa_group[grepl("OTRA", incidTrafCatLatest$causa)]   <- "other"
incidTrafCatLatest$causa_group[is.na(incidTrafCatLatest$causa_group)]     <- "other"

#Con ello resumimos un total de 11 iconos (que podría aumentarse) para representar todas las incidencias, 
#asignando los NA al valor "other".
unique(incidTrafCatLatest$causa_group)

incidIcons <- iconList(closed)









head(incidTrafCatLatest)
# colnames((incidTrafLatest))


head(quakes)
mutate(quakes, group = cut(mag, breaks = c(0, 5, 6, Inf), labels = c("blue", "green", "orange"))) -> mydf
colnames(incidTrafCatLatest)

### I edit this png file and created my own marker.
### https://raw.githubusercontent.com/lvoogdt/Leaflet.awesome-markers/master/dist/images/markers-soft.png
incidIcons <- iconList(fog         = makeIcon("icon/01.niebla.png", iconWidth = 24, iconHeight =32),
                       snow        = makeIcon("icon/02.nieve.svg",  iconWidth = 24, iconHeight =32),
                       wind        = makeIcon("icon/03.viento.png", iconWidth = 24, iconHeight =32),
                       rain        = makeIcon("icon/04.lluvia.svg", iconWidth = 24, iconHeight =32),
                       ice         = makeIcon("icon/05.hielo.svg", iconWidth = 24, iconHeight =32),
                       closed      = makeIcon("icon/06.cerrado.svg", iconWidth = 24, iconHeight =32),
                       accident    = makeIcon("icon/07.accidente.svg", iconWidth = 24, iconHeight =32),
                       congestion  = makeIcon("icon/08.congestion.svg", iconWidth = 24, iconHeight =32),
                       maintenance = makeIcon("icon/09.mantenimiento.png", iconWidth = 24, iconHeight =32),
                       works       = makeIcon("icon/10.obras.svg", iconWidth = 24, iconHeight =32),
                       other       = makeIcon("icon/11.otros.svg", iconWidth = 24, iconHeight =32))


leaflet(data = incidTrafCatLatest[1:100,]) %>% 
  addTiles() %>%
  addMarkers(lng=~px, 
             lat=~py,
             icon = ~incidIcons[causa_group],
             popup=~paste0("'<p style=\"color:blue\">Tipo:</p>" , causa, "<br>",
                           "Nivel: ", nivel, "<br>",
                           "Carretera: ", carretera, "<br>",
                           "Sentido: ", sentido, "<br>",
                           "Municipio: ", poblacion, "<br>",
                           "Fecha: ", fechahora_, "<br>"))
             





######################
# Incidente re-route #
######################
#Vilafranca - El Vendrell -Tarragona -Port Aventura. Autocars del Penedés
paradasL0808 <- read.csv(file = "data/r/paradasL0808.csv", header = TRUE, encoding = "utf-8")
paradaJuliCesar <- paradasL0808[paradasL0808$FID==9166,]
paradaJuliCesar$Latitude
paradaJuliCesar$Longitude

