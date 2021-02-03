
options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")


library(sp)       #Datos espaciales
library(rgdal)    #Lectura de cartograf??as
library(rgeos)    #Lectura de cartograf??as
library(maptools) #Lectura de cartograf??as
library(readxl)   #Lectura de ficheros Excel
library(tmap)     #Representaci??n de funciones
library(stringr)  #Para str_split_fixed
library(leaflet) #Mapas web interactivos.

load("data/r/catalunyaPoblacMap.RData")

#Representamos el mapa con leaflet definiendo una escala crom??tica amarillo-naranja-marr??n.
leaflet(catalunyaPoblacMap, 
        options = leafletOptions(attributionControl = FALSE)) %>%
  addPolygons(data=catalunyaPoblacMap, stroke=TRUE, opacity = 0.5, fillOpacity = 0.7, 
              color="grey10",
              fillColor = ~colorQuantile("YlOrBr", n=9, Poblacion, na.color = "white")(Poblacion))


#Permite a??adir la capa del OpenStreetMap
leaflet(CCAA_MAP,options = leafletOptions(attributionControl = FALSE)) %>%
  addTiles()%>%
  addPolygons(data=CCAA_MAP, stroke=TRUE, color="grey10")

#Se le puede a??adir distinto grado de opacidad.  
leaflet(CCAA_MAP,options = leafletOptions(attributionControl = FALSE)) %>%
  addTiles()%>%
  addPolygons(data=CCAA_MAP, stroke=TRUE, opacity = 0.25, fillOpacity = 0.27,color="grey10",
              fillColor = ~colorQuantile("YlOrBr", n=9, SALARIO, na.color = "white")(SALARIO))
#Se le puede dar a Export en el men?? de gr??ficas -> Save as web page.
#Este mapa utiliza una proyecci??n mercator, que est?? muy bien para zonas cercanas al ecuador, pero 
#los polos muy distorsionados.

# Para situar marcadores
#Es decir, representar puntos.
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



