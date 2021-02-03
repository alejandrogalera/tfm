
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
load("data/r/catalunyaPoblacMap.RData") #Para el mapa base.
load("data/r/paradasLineasNoDup.RData") #Para un tipo de marcadores
#load("data/r/incidentesTrafico.RData")  #Para el otro tipo de marcadores: incidentes de tráfico.
load("data/r/fullData.RData")           #Para el gasto medio en transporte por municipio.

#Representamos el mapa con leaflet definiendo una escala cromática amarillo-naranja-marrón.
leaflet(catalunyaPoblacMap, 
        options = leafletOptions(attributionControl = FALSE)) %>%
  addPolygons(data=catalunyaPoblacMap, stroke=TRUE, opacity = 0.5, fillOpacity = 0.7, 
              color="grey10",
              fillColor = ~colorQuantile("YlOrBr", n=9, Poblacion, na.color = "white")(Poblacion))

#########################
# catalunyaPoblacionMap #
#########################
#Permite añadir la capa del OpenStreetMap
leaflet(catalunyaPoblacMap,options = leafletOptions(attributionControl = FALSE)) %>%
  addTiles()%>%
  addPolygons(data=catalunyaPoblacMap, stroke=TRUE, color="grey10")

#Se le puede añadir distinto grado de opacidad.  
htmlLeafletOSMPoblacion = 
  leaflet(catalunyaPoblacMap,options = leafletOptions(attributionControl = FALSE)) %>%
  addTiles()%>%
  addPolygons(data=catalunyaPoblacMap, stroke=TRUE, opacity = 0.35, fillOpacity = 0.37,color="grey10",
              fillColor = ~colorQuantile("YlOrBr", n=9, Poblacion, na.color = "white")(Poblacion))
saveWidget(htmlLeafletOSMPoblacion, file="web/maps/leafletOSMPoblacion.html")

#Exportamos el gráfico con la proyección correcta (mercator), que distorsiona en latitudes mucho más altas.

######################
# paradasLineasNoDup #
######################
#A continuación, situamos los marcadores correspondientes a las paradas de autobús.
#Antes, pasamos a double las columnas COORD_X y COORD_Y
paradasLineasNoDup$Longitude <- as.double(paradasLineasNoDup$COORD_X)/100000
paradasLineasNoDup$Latitude <-  as.double(paradasLineasNoDup$COORD_Y)/100000
paradasLineasNoDup$COORD_X <- NULL
paradasLineasNoDup$COORD_Y <- NULL

#Añadimos como marcadores los puntos de una línea.
paradasL0242 <- paradasLineasNoDup[paradasLineasNoDup$Nombre_d_1==paradasLineasNoDup$Nombre_d_1[1],]

a <- as.data.frame(paradasCat@coords[c(1:10),])

dat <- data.frame(Longitude = paradasL0242$Longitude,
                  Latitude = paradasL0242$Latitude)

dat2 <- data.frame(Longitude = a$coords.x1,
                  Latitude = a$coords.x2)


leaflet(data=dat) %>%
  addTiles()%>%  
  addMarkers(data=dat2,lng=~Longitude, lat=~Latitude)



datos_map<-data.frame(longx=c(-3.741274,-3.718765,-3.707027, -3.674605,-3.709559 ),
                      laty=c(40.38479, 40.36751, 40.45495, 40.50615, 40.42059))

leaflet(data=datos_map) %>%
  addTiles()%>%  
  addMarkers(data=datos_map,lng=~longx, lat=~laty)

#Se le podr??a asignar m??s informaci??n a los marcadores.

# Cargamos datos desde fichero 
Datos <- read.csv(file="3.EstudioR/cartoclase/Data_Housing_Madrid.csv",header=TRUE)

hist(Datos$house.price)

#Para no representar todos, cojo una muestra de 100:
m <- leaflet(data=Datos[sample(nrow(Datos),100),]) %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addMarkers(lng=~longitude,
             lat=~latitude,
             popup=~paste0(type.house, " - ", house.price, " euros"))
#Basta con a??adir en el popup el tipo de la casa y el precio a la funci??n addMarkers.
m  # Print the map



