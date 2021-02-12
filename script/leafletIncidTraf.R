#!/usr/bin/env Rscript
#Setup del sistema de codificación.
#Este script está preparado para ser ejecutado una vez y depurar la generación de distintos scripts específicos por 
#Tareas.
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

library(tmaptools) #Para OSRM
library(osrm)


#Manejo de argumentos de entrada con valor por defecto del WORKDIR si no se 
#actualiza por argumentos de línea de comandos.
WORKDIR <- '.'
args = commandArgs(trailingOnly = TRUE)
if (length(args)>0)
{
  cat("Setting working dir to ",args[1])
  WORKDIR <- args[1]
  setwd(WORKDIR)
}


#Cargamos los datos procesados
load("data/r/catalunyaPoblacMap.RData")          #Para el mapa base.
load("data/r/paradasLineasNoDupMunicipio.RData") #Para un tipo de marcadores
#load("data/r/incidentesTrafico.RData")   #Para el otro tipo de marcadores: incidentes de tráfico.
load("data/r/fullData.RData")                    #Para el gasto medio en transporte por municipio.

#Guardamos para la web el listado de poblaciones.
#Para su compatibilidad con los datos de Esri, lo pasamos a mayúsculas además de ordenarlas.
orderedPobList <- catalunyaPoblacMap$NAME_4[order(catalunyaPoblacMap$NAME_4)]
write(toupper(orderedPobList), file = "web/select/poblacion.txt")



#Primero leemos de data/r/
dir("script/")
incidTrafLatest <- read.csv("script/incid_traf_latest.csv", header = TRUE, sep = ',', encoding = 'utf-8')
#Reformateamos las mayusculas/minúsculas. Por ejemplo, en la variable sentido existe
#tanto "AMBOS SENTIDOS" como "Ambos sentidos"
unique(incidTrafLatest$sentido)
# [1] Ambos sentidos                                              AMBOS SENTIDOS               
# [4] CRECIENTE DE LA KILOMETRICA   DECRECIENTE DE LA KILOMETRICA SUR                          
# [7] NORTE                         ESTE
incidTrafLatest$sentido[incidTrafLatest$sentido=="Ambos sentidos"]<- "AMBOS SENTIDOS"


#Filtramos por la comunidad autónoma bajo estudio.
incidTrafCatLatest <- incidTrafLatest[incidTrafLatest$autonomia=="CATALUÑA",]


#Depuramos los missings.
incidTrafCatLatest$causa2  <- lapply(incidTrafCatLatest$causa, trimws)
incidTrafCatLatest <- incidTrafCatLatest[incidTrafCatLatest$causa2!="",]
incidTrafCatLatest$causa <- unlist(incidTrafCatLatest$causa2)
incidTrafCatLatest$causa2 <- NULL

incidTrafCatLatest$poblacion2  <- lapply(incidTrafCatLatest$poblacion, trimws)
incidTrafCatLatest <- incidTrafCatLatest[incidTrafCatLatest$poblacion2!="",]
incidTrafCatLatest$poblacion <- unlist(incidTrafCatLatest$poblacion2)
incidTrafCatLatest$poblacion2 <- NULL



#Obtenemos los posibles valores para los combo-box (select html) de la web
getUniqueAndSave <- function(vect, filename) 
{  
  #Encoding(vect) <- "UTF-8"
  #vect <- vect[!is.na(vect)]
  aux <- paste( as.vector(trimws(unique(vect))), collapse='\n')
  cat(aux)
  Encoding(aux) <- "UTF-8"
  write(aux, as.character(filename))
  return(aux) 
}

colnames(incidTrafCatLatest)
#Guardamos los listados txt en el directorio select relativo al workdir
filef <- paste(WORKDIR, "/web/select/autonomia.txt", sep = "")
getUniqueAndSave(incidTrafLatest$autonomia, paste(WORKDIR, "/web/select/autonomia.txt", sep = ""))
getUniqueAndSave(incidTrafCatLatest$carretera, paste(WORKDIR, "/web/select/carretera.txt", sep = ""))
getUniqueAndSave(incidTrafLatest$causa, paste(WORKDIR, "/web/select/causa.txt", sep = ""))
#La población ya la hemos almacenado a partir de catalunyaPoblacMap al principio del script.
getUniqueAndSave(incidTrafLatest$nivel, paste(WORKDIR, "/web/select/nivel.txt", sep = ""))
getUniqueAndSave(incidTrafLatest$tipo, paste(WORKDIR, "/web/select/tipo.txt", sep = ""))
#https://stackoverflow.com/questions/46031256/populating-a-dropdown-list-with-values-from-a-text-file
unique(incidTrafLatest$sentido)

#####################
# Creación icon set #
#####################
#https://stat.ethz.ch/R-manual/R-devel/library/base/html/trimws.html

#Hay que realizar una agrupación semántica de todas las causas que se puedan representar con un mismo icono.
#Por ejemplo, "CERRADO TAL CAMINO" = "CERRADO" = "CARRETERA CORTADA EN ESTE SENTIDO".
#Del mismo modo, "OBRAS EN GENERAL" = "OBRAS" = "MANTENIMIENTO" = "REASFALTADO".
#Además, para hacer uso del iconList, es necesario que el grupo sobre el que se discrimina la representación 
#de los iconos sea de tipo string sin contener espacios.
#El nuevo campo recibirá el nombre de causa_group

#Incidentes de obras, vías cerradas y mantenimiento.
#El sufijo entero indica el nivel de gravedad, siendo 1, verde; 2, amarillo; 3, rojo y 4, negro.
incidTrafCatLatest$causa_group[grepl("CERRAD|CORTAD", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "closed_1"
incidTrafCatLatest$causa_group[grepl("CERRAD|CORTAD", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "closed_2" 
incidTrafCatLatest$causa_group[grepl("CERRAD|CORTAD", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "closed_3" 
incidTrafCatLatest$causa_group[grepl("CERRAD|CORTAD", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "closed_4" 

incidTrafCatLatest$causa_group[grepl("OBRA|ASFALT", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "works_1"
incidTrafCatLatest$causa_group[grepl("OBRA|ASFALT", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "works_2" 
incidTrafCatLatest$causa_group[grepl("OBRA|ASFALT", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "works_3" 
incidTrafCatLatest$causa_group[grepl("OBRA|ASFALT", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "works_4" 

incidTrafCatLatest$causa_group[grepl("MANTENIM", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "maintenance_1"
incidTrafCatLatest$causa_group[grepl("MANTENIM", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "maintenance_2" 
incidTrafCatLatest$causa_group[grepl("MANTENIM", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "maintenance_3" 
incidTrafCatLatest$causa_group[grepl("MANTENIM", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "maintenance_4" 

#Incidentes meteorológicos
incidTrafCatLatest$causa_group[grepl("NIEBLA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "fog_1"
incidTrafCatLatest$causa_group[grepl("NIEBLA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "fog_2" 
incidTrafCatLatest$causa_group[grepl("NIEBLA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "fog_3" 
incidTrafCatLatest$causa_group[grepl("NIEBLA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "fog_4" 

incidTrafCatLatest$causa_group[grepl("NIEVE", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "fog_1"
incidTrafCatLatest$causa_group[grepl("NIEVE", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "fog_2" 
incidTrafCatLatest$causa_group[grepl("NIEVE", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "fog_3" 
incidTrafCatLatest$causa_group[grepl("NIEVE", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "fog_4" 

incidTrafCatLatest$causa_group[grepl("VIENTO", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "wind_1"
incidTrafCatLatest$causa_group[grepl("VIENTO", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "wind_2" 
incidTrafCatLatest$causa_group[grepl("VIENTO", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "wind_3" 
incidTrafCatLatest$causa_group[grepl("VIENTO", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "wind_4" 

incidTrafCatLatest$causa_group[grepl("LLUVIA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "rain_1"
incidTrafCatLatest$causa_group[grepl("LLUVIA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "rain_2" 
incidTrafCatLatest$causa_group[grepl("LLUVIA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "rain_3" 
incidTrafCatLatest$causa_group[grepl("LLUVIA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "rain_4" 

incidTrafCatLatest$causa_group[grepl("HIELO", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "ice_1"
incidTrafCatLatest$causa_group[grepl("HIELO", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "ice_2" 
incidTrafCatLatest$causa_group[grepl("HIELO", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "ice_3" 
incidTrafCatLatest$causa_group[grepl("HIELO", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "ice_4" 


#Accidentes y otros.
incidTrafCatLatest$causa_group[grepl("CONGESTION", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "congestion_1"
incidTrafCatLatest$causa_group[grepl("CONGESTION", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "congestion_2" 
incidTrafCatLatest$causa_group[grepl("CONGESTION", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "congestion_3" 
incidTrafCatLatest$causa_group[grepl("CONGESTION", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "congestion_4" 

incidTrafCatLatest$causa_group[grepl("ACCIDENTE", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "accident_1"
incidTrafCatLatest$causa_group[grepl("ACCIDENTE", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "accident_2" 
incidTrafCatLatest$causa_group[grepl("ACCIDENTE", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "accident_3" 
incidTrafCatLatest$causa_group[grepl("ACCIDENTE", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "accident_4" 

incidTrafCatLatest$causa_group[grepl("OTRO|OTRA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="VERDE"] <- "other_1"
incidTrafCatLatest$causa_group[grepl("OTRO|OTRA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="AMARILLO"] <- "other_2" 
incidTrafCatLatest$causa_group[grepl("OTRO|OTRA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="ROJO"] <- "other_3" 
incidTrafCatLatest$causa_group[grepl("OTRO|OTRA", incidTrafCatLatest$causa) & incidTrafCatLatest$nivel=="NEGRO"] <- "other_4" 
incidTrafCatLatest$causa_group[is.na(incidTrafCatLatest$causa_group)]     <- "other_1"


#Con ello resumimos un total de 11 iconos (que podría aumentarse) para representar todas las incidencias, 
#asignando los NA al valor "other".
unique(incidTrafCatLatest$causa_group)
colnames(incidTrafCatLatest)

### I edit this png file and created my own marker.
### https://raw.githubusercontent.com/lvoogdt/Leaflet.awesome-markers/master/dist/images/markers-soft.png
incidIcons <- iconList(fog_1         = makeIcon("icon/01.1.niebla.png", iconWidth = 24, iconHeight =24),
                       fog_2         = makeIcon("icon/01.2.niebla.png", iconWidth = 24, iconHeight =24),
                       fog_3         = makeIcon("icon/01.3.niebla.png", iconWidth = 24, iconHeight =24),
                       fog_4         = makeIcon("icon/01.4.niebla.png", iconWidth = 24, iconHeight =24),
                       snow_1        = makeIcon("icon/02.1.nieve.png",  iconWidth = 24, iconHeight =24),
                       snow_2        = makeIcon("icon/02.2.nieve.png",  iconWidth = 24, iconHeight =24),
                       snow_3        = makeIcon("icon/02.3.nieve.png",  iconWidth = 24, iconHeight =24),
                       snow_4        = makeIcon("icon/02.4.nieve.png",  iconWidth = 24, iconHeight =24),
                       wind_1        = makeIcon("icon/03.1.viento.png", iconWidth = 24, iconHeight =24),
                       wind_2        = makeIcon("icon/03.2.viento.png", iconWidth = 24, iconHeight =24),
                       wind_3        = makeIcon("icon/03.3.viento.png", iconWidth = 24, iconHeight =24),
                       wind_4        = makeIcon("icon/03.4.viento.png", iconWidth = 24, iconHeight =24),
                       rain_1        = makeIcon("icon/04.1.lluvia.png", iconWidth = 24, iconHeight =24),
                       rain_2        = makeIcon("icon/04.2.lluvia.png", iconWidth = 24, iconHeight =24),
                       rain_3        = makeIcon("icon/04.3.lluvia.png", iconWidth = 24, iconHeight =24),
                       rain_4        = makeIcon("icon/04.4.lluvia.png", iconWidth = 24, iconHeight =24),
                       ice_1         = makeIcon("icon/05.1.hielo.png", iconWidth = 24, iconHeight =24),
                       ice_2         = makeIcon("icon/05.2.hielo.png", iconWidth = 24, iconHeight =24),
                       ice_3         = makeIcon("icon/05.3.hielo.png", iconWidth = 24, iconHeight =24),
                       ice_4         = makeIcon("icon/05.4.hielo.png", iconWidth = 24, iconHeight =24),
                       closed_1      = makeIcon("icon/06.1.cerrado.png", iconWidth = 24, iconHeight =24),
                       closed_2      = makeIcon("icon/06.2.cerrado.png", iconWidth = 24, iconHeight =24),
                       closed_3      = makeIcon("icon/06.3.cerrado.png", iconWidth = 24, iconHeight =24),
                       closed_4      = makeIcon("icon/06.4.cerrado.png", iconWidth = 24, iconHeight =24),
                       accident_1    = makeIcon("icon/07.1.accidente.png", iconWidth = 24, iconHeight =24),
                       accident_2    = makeIcon("icon/07.2.accidente.png", iconWidth = 24, iconHeight =24),
                       accident_3    = makeIcon("icon/07.3.accidente.png", iconWidth = 24, iconHeight =24),
                       accident_4    = makeIcon("icon/07.4.accidente.png", iconWidth = 24, iconHeight =24),
                       congestion_1  = makeIcon("icon/08.1.congestion.png", iconWidth = 24, iconHeight =24),
                       congestion_2  = makeIcon("icon/08.2.congestion.png", iconWidth = 24, iconHeight =24),
                       congestion_3  = makeIcon("icon/08.3.congestion.png", iconWidth = 24, iconHeight =24),
                       congestion_4  = makeIcon("icon/08.4.congestion.png", iconWidth = 24, iconHeight =24),
                       maintenance_1 = makeIcon("icon/09.1.mantenimiento.png", iconWidth = 24, iconHeight =24),
                       maintenance_2 = makeIcon("icon/09.2.mantenimiento.png", iconWidth = 24, iconHeight =24),
                       maintenance_3 = makeIcon("icon/09.3.mantenimiento.png", iconWidth = 24, iconHeight =24),
                       maintenance_4 = makeIcon("icon/09.4.mantenimiento.png", iconWidth = 24, iconHeight =24),
                       works_1       = makeIcon("icon/10.1.obras.png", iconWidth = 24, iconHeight =24),
                       works_2       = makeIcon("icon/10.2.obras.png", iconWidth = 24, iconHeight =24),
                       works_3       = makeIcon("icon/10.3.obras.png", iconWidth = 24, iconHeight =24),
                       works_4       = makeIcon("icon/10.4.obras.png", iconWidth = 24, iconHeight =24),
                       other_1       = makeIcon("icon/11.1.otros.png", iconWidth = 24, iconHeight =24),
                       other_2       = makeIcon("icon/11.2.otros.png", iconWidth = 24, iconHeight =24),
                       other_3       = makeIcon("icon/11.3.otros.png", iconWidth = 24, iconHeight =24),
                       other_4       = makeIcon("icon/11.4.otros.png", iconWidth = 24, iconHeight =24))


htmlLeafletOSMIncidTraf <- leaflet(data = incidTrafCatLatest[1:100,]) %>% 
  addTiles() %>%
  addMarkers(lng=~px, 
             lat=~py,
             icon = ~incidIcons[causa_group],
             popup=~paste0("<p style='color:blue'>Incidente</p>",
                           "Tipo: " , causa, "<br>",
                           "Nivel: ", nivel, "<br>",
                           "Carretera: ", carretera, "<br>",
                           "Sentido: ", sentido, "<br>",
                           "Municipio: ", poblacion, "<br>",
                           "Fecha: ", fechahora_, "<br>"))
saveWidget(htmlLeafletOSMIncidTraf, file="/maps/htmlLeafletOSMIncidTraf.html")




######################
# Incidente re-route #
######################
#Vilafranca - El Vendrell -Tarragona -Port Aventura. Autocars del Penedés
paradasL0808 <- read.csv(file = "data/r/paradasL0808.csv", header = TRUE, encoding = "utf-8")
paradaJuliCesar <- paradasL0808[paradasL0808$FID==9166,]
paradaJuliCesar$Latitude
paradaJuliCesar$Longitude


#ROUTING
objetivo<-"Villafranca del Penedes, Tarragona"
geo_output<-geocode_OSM(objetivo, details=TRUE, return.first.only = TRUE, as.data.frame = T )

laty=geo_output$lat
lonx=geo_output$lon

leaflet(data.frame(lonx,laty)) %>% 
  addTiles() %>% 
  addMarkers(lng=~lonx, lat=~laty)




#Al revés si tengo una localización laty=40.4, lonx=-3.74, puedo encontrar la dirección

rev_geocode_OSM(x=lonx, y=laty)


destino<-"Tarragona, Tarragona"
geo_output<-geocode_OSM(destino, details=TRUE, return.first.only = TRUE, as.data.frame = T )


laty_destino=geo_output$lat
lonx_destino=geo_output$lon

ruta<-osrmRoute(src= c(lonx,laty), dst = c(lonx_destino, laty_destino), overview =  "full", osrm.profile = "car")
ruta2<-osrmRoute(src= c(lonx,laty), dst = c(lonx_destino, laty_destino), overview =  "full", osrm.profile = "car", exclude="motorway")

#proporciona el tiempo en minutos y la distancia en kilómetros
#ruta@data
nrow(ruta)
nrow(ruta2)

# Ahora podemos añadirlo al leafleat
leaflet(data=data.frame(ruta)) %>% 
  addTiles() %>%
  addPolylines(lng=~lon, lat=~lat, color="red")
#,label = (paste0(ruta$duration, " minutos, ", ruta$distance, " kms")))
#addMarkers(lng=~lon, lat=~lat) %>% 
leaflet(data=data.frame(ruta2)) %>% 
  addTiles() %>%
  addPolylines(lng=~lon, lat=~lat, color="red")



