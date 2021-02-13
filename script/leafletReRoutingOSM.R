#!/usr/bin/env Rscript
#Script para la ejecución del enrutado.
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
load("data/r/paradasL1196.RData")


######################
# Incidente re-route #
######################
#Crearemos un nuevo dataset con la línea a estudiar y una columna adicional para asociar un icono en el mapa de iconos.
#El tramo de la línea L1196 se correponde con Barcelona - Granollers.
head(paradasL1196)

htmlLeafletOSMParadasL1196 <- leaflet(data = paradasL1196) %>% 
  addTiles() %>%
  addMarkers(data=paradasL1196,
             lng=~Longitude, lat=~Latitude,
             popup=~paste0("<p style='color:blue'>Parada de bus</p>",
                           "FID: " , FID, "<br>",
                           "Nombre: ", Nombre_de_, "<br>",
                           "Linea: ", Nombre_d_1, "<br>",
                           "Descripcion: ", Descripcio, "<br>",                           
                           "Operador: ", Operador, "<br>",
                           "Municipio: ", Municipio, "<br>"))
htmlLeafletOSMParadasL1196

#Calculamos la ruta entre dos de las paradas de la línea: 
#DESDE: Parada de bus FID: 14121
#Nombre: Av Meridiana-S'Agar (Barcelona)
#Linea: L1196
#Descripcin: Barcelona-Granollers-Llinars del Valls per autop.
#Operador: Empresa Sagals, SA
#Municipio: Barcelona
origenParada <- paradasL1196[paradasL1196$FID==14121,]

#HASTA: Parada de bus FID: 22580
#Nombre: ctra. el Masnou - Sant Juli Ms
#Linea: L1196
#Descripcin: Barcelona-Granollers-Llinars del Valls per autop.
#Operador: Empresa Sagals, SA
#Municipio: Granollers
destinoParada <- paradasL1196[paradasL1196$FID==22580,]

#Obtenemos sendos geocodeOSM para las paradas
origenGeoOSM <- rev_geocode_OSM(x=origenParada$Longitude, y=origenParada$Latitude)
destinoGeoOSM <- rev_geocode_OSM(x=destinoParada$Longitude, y=destinoParada$Latitude)

#ROUTING
route1<-osrmRoute(src= c(origenParada$Longitude, origenParada$Latitude), 
                  dst= c(destinoParada$Longitude, destinoParada$Latitude), overview =  "full", osrm.profile = "car")

htmlLeafletOSMRoute1L1196 <- leaflet(data = paradasL1196) %>% 
  addTiles() %>%
  addMarkers(data=paradasL1196,
             lng=~Longitude, lat=~Latitude,
             popup=~paste0("<p style='color:blue'>Parada de bus</p>",
                           "FID: " , FID, "<br>",
                           "Nombre: ", Nombre_de_, "<br>",
                           "Linea: ", Nombre_d_1, "<br>",
                           "Descripcion: ", Descripcio, "<br>",                           
                           "Operador: ", Operador, "<br>",
                           "Municipio: ", Municipio, "<br>")) %>%
  addPolylines(data=data.frame(route1), lng=~lon, lat=~lat, color="red")
htmlLeafletOSMRoute1L1196
saveWidget(htmlLeafletOSMRoute1L1196, file="web/maps/htmlLeafletOSMRoute1L1196.html")


##################################
#Adición del incidente de tráfico#
##################################
#Añadimos el campo group para el iconMap
paradasL1196$group <- "busstop"

#Hay que añadirlo como un punto más del listado de paradas y setear un mapIcon.
#Supongamos que el incidente de tráfico es un corte en el punto 41.532603,2.2188313, y se ha dado de alta con el formulario
#etc, por lo que leeríamos de la última línea del fichero de incidencias la latitud y longitud:
incidTrafLatest <- read.csv("web/incid_traf_latest.csv", header = TRUE, sep = ",", encoding = "UTF-8")

#Obtenemos la última fila, que será el incidente nuevo.
latestIncident <- incidTrafCatLatest[nrow(incidTrafLatest),]
coordIncidente <- c(latestIncident$px, latestIncident$py)

#Aquí es donde vamos a asignar nuestro valor para el ejemplo, en caso de que se ejecute de forma manual con 
#WORKDIR='.'
#Si el directorio de trabajo es otro, significa que se ha invocado desde la web u otro script, por lo que no se haría esta
#asignación.
if (WORKDIR==".") { coordIncidente <- c(2.22, 41.532)}

#Añadimos las coordenadas al listado de paradas, pero en el campo "group" seteamos el tipo "closed_4".
colnames(paradasL1196)
incidentInStopDF <- paradasL1196[1,]
#Rellenamos el incidentInStopDF con los datos de: 
#c(max(paradasL1196$FID)+1, "CERRADA", "Cono", "Incidente carretera cerrada", "-", 
#                          coordIncidente[1], coordIncidente[2], "Mollet del Vallés", 0, 0, "closed_4"))
#Basta con lat, long y group, aunque también rellenaremos el FID y municipio.
incidentInStopDF$FID <- max(paradasL1196$FID)+1
incidentInStopDF$Latitude <- as.double(coordIncidente[2])
incidentInStopDF$Longitude <- as.double(coordIncidente[1])
incidentInStopDF$Municipio <- "Mollet del Vallés"
incidentInStopDF$Poblacion <- 0
incidentInStopDF$COD_INE <- 0
incidentInStopDF$group <- "closed_4"

paradasEIncidentes <- rbind(paradasL1196, incidentInStopDF)

#####################
# Creación icon set #
#####################

incidParadaIcons <- iconList(busstop = makeIcon("web/icon/42561-bus-stop-icon.png", iconWidth = 24, iconHeight =24),
                             closed_4 = makeIcon("web/icon/06.4.cerrado.png", iconWidth = 24, iconHeight =24))

#Calculamos la ruta alternativa
route2<-osrmRoute(src= c(origenParada$Longitude, origenParada$Latitude), 
                  dst= c(destinoParada$Longitude, destinoParada$Latitude), overview =  "full", osrm.profile = "car", exclude="motorway")

htmlLeafletOSMRoute2L1196 <- leaflet(data = paradasEIncidentes) %>% 
  addTiles() %>%
  addMarkers(data=paradasEIncidentes,
             lng=~Longitude, lat=~Latitude,
             icon = ~incidParadaIcons[group],
             popup=~paste0("<p style='color:blue'>Parada de bus</p>",
                           "FID: " , FID, "<br>",
                           "Nombre: ", Nombre_de_, "<br>",
                           "Linea: ", Nombre_d_1, "<br>",
                           "Descripcion: ", Descripcio, "<br>",                           
                           "Operador: ", Operador, "<br>",
                           "Municipio: ", Municipio, "<br>")) %>%
  addPolylines(data=data.frame(route2), lng=~lon, lat=~lat, color="blue")
htmlLeafletOSMRoute2L1196

saveWidget(htmlLeafletOSMRoute2L1196, file="web/maps/htmlLeafletOSMRoute2L1196.html")


########################################
# Representación conjunta de las rutas #
########################################
#Creamos un índice para ambas
route1.df <- route1 %>% dplyr::mutate( id = dplyr::row_number())
route2.df <- route2 %>% dplyr::mutate( id = dplyr::row_number())

route1.df <- route1.df %>%
  select(id, lat, lon) %>%
  rename(latitude = lat, longitude = lon)
route2.df <- route2.df %>%
  select(id, lat, lon) %>%
  rename(latitude = lat, longitude = lon)

#Hacemos un bind_rows de ambas rutas:
df.sp <- dplyr::bind_rows(route1.df, route2.df)
head(df.sp)

#Ahora creamos los spatialLines-objects con las funciones de las librerías maptools y sp.
coordinates(df.sp) <- c("longitude", "latitude")

#Creamos una lista por id e inicializamos el contador para entrar en el bucle for 
#de creación de las SpatialLines.
id.list <- sp::split( df.sp, df.sp[["id"]] )
id <- 1

#Para cada id, creamos una Spatial Line que conecte todos los puntos y asignamos una proyección
for ( i in id.list ) {
  event.lines <- SpatialLines( list( Lines( Line( i[1]@coords ), ID = id ) ),
                               proj4string = CRS( "+init=epsg:4258" ) )
  if ( id == 1 ) {
    sp_lines  <- event.lines
  } else {
    sp_lines  <- spRbind( sp_lines, event.lines )
  }
  id <- id + 1
}

leaflet() %>%
  addTiles() %>%
  addCircles(data = route1, lng = ~lon, lat = ~lat, radius=20, color = "red", group = "route1") %>% 
  addCircles(data = route2, lng = ~lon, lat = ~lat, radius=20, color = "blue", group = 'route2') %>%
  addPolylines(data = sp_lines)
#Esto representa las dos rutas y en azul la conexión de una ruta a la otra. Las paradas alternativas deberían estar
#en la zona marcada como azul.
