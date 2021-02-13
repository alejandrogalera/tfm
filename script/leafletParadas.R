
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

#Representamos el mapa con leaflet definiendo una escala cromática amarillo-naranja-marrón.
leaflet(catalunyaPoblacMap, 
        options = leafletOptions(attributionControl = FALSE)) %>%
  addPolygons(data=catalunyaPoblacMap, stroke=TRUE, opacity = 0.5, fillOpacity = 0.7, 
              color="grey10",
              fillColor = ~colorQuantile("YlOrBr", n=9, Poblacion, na.color = "white")(Poblacion))
#Podemos representar otros parámetros haciendo uso del dataset fullData que contiene 
#paradas, líneas, población y los tres tipos de gastos por vivienda en el sector transporte.
load("data/r/gasto1_vehiculos.RData")
load("data/r/gasto2_uso_vehiculo.RData")
load("data/r/gasto3_tra_pub.RData")

#Añadimos la información del gasto al dataset de catalunyaPoblacMap
catalunyaFull <- catalunyaPoblacMap
catalunyaFull$Gasto_tra_pub[catalunyaFull$Poblacion>=100000] <-
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="100,000 or more inhabitants"]
catalunyaFull$Gasto_tra_pub[catalunyaFull$Poblacion<100000] <-
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="From 50,000 to 100,000 inhabitants"]
catalunyaFull$Gasto_tra_pub[catalunyaFull$Poblacion<50000] <-
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="From 20,000 to 50,000 inhabitants"]
catalunyaFull$Gasto_tra_pub[catalunyaFull$Poblacion<20000] <-
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="From 10,000 to 20,000 inhabitants"]
catalunyaFull$Gasto_tra_pub[catalunyaFull$Poblacion<10000] <-
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="Less than 10,000 inhabitants"]

#La siguiente función da error: "Cut() error - 'breaks' are not unique" porque coinciden los quantiles, y al 
#hacer cut, se generan breaks con el mismo valor.
#leaflet(catalunyaFull, 
#        options = leafletOptions(attributionControl = TRUE)) %>%
#  addPolygons(data=catalunyaFull, stroke=TRUE, opacity = 0.5, fillOpacity = 0.7, 
#              color="grey10", 
#              fillColor = ~colorQuantile("Blues", n=5 ,Gasto_tra_pub, na.color = "white")(Gasto_tra_pub))


catalunyaFull$CC_4 <- NULL
quantile(catalunyaFull$Gasto_tra_pub)
#Si los cuantiles son iguales, la función de leaflet da error "Cut() error - 'breaks' are not unique"
#Se puede realizar lo que propone la comunidad StackOverflow https://stackoverflow.com/questions/16184947/cut-error-breaks-are-not-unique
#o añadir un diferencial para que los cuantiles no coincidan y por tanto el cut no detecte breaks coincidentes.
addDifferential <- function(x) {
  return(x+runif(1, 0.0001, 0.0010))
}

catalunyaFull$Gasto_tra_pub <- sapply(catalunyaFull$Gasto_tra_pub,addDifferential)
#Ya tenemos cuantiles diferentes.
quantile(catalunyaFull$Gasto_tra_pub)

leaflet(catalunyaFull, 
        options = leafletOptions(attributionControl = TRUE)) %>%
        addPolygons(data=catalunyaFull, stroke=TRUE, opacity = 0.5, fillOpacity = 0.7, 
        color="grey10", 
        fillColor = ~colorQuantile("Blues", n=5 ,Gasto_tra_pub, na.color = "white")(Gasto_tra_pub))

#Se puede representar cualquiera de estas variables:
colnames(fullData@data)
#[1] "FID"                "Nombre_de_"         "Nombre_d_1"        
#[4] "Descripcio"         "Operador"           "Longitude"         
#[7] "Latitude"           "Municipio"          "Poblacion"         
#[10] "COD_INE"            "Gasto_vehiculo"     "Gasto_uso_veh_pers"
#[13] "Gasto_tra_pub"      "Gasto_total"        "X"    

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
htmlLeafletOSMPoblacion
#Exportamos el gráfico con la proyección correcta (mercator), que distorsiona en latitudes mucho más altas.

######################
# paradasLineasNoDup #
######################
#A continuación, situamos los marcadores correspondientes a las paradas de autobús.
#Añadimos como marcadores los puntos de una línea.
#Representemos el caso de estudio de la línea, por ejemplo, L1196
#L1196- GRANOLLERS - BARCELONA
paradasL1196 <- paradasLineasNoDup[paradasLineasNoDup$Nombre_d_1=="L1196",]
colnames(paradasLineasNoDup)

#Barcelona-Granollers-Llinars del Vallès, empresa Sagalès SA
save(paradasL1196, file = "data/r/paradasL1196.RData")

dat <- data.frame(Longitude = paradasL1196$Longitude,
                  Latitude = paradasL1196$Latitude)

htmlLeafletOSMParadasL1196 <- leaflet(data=dat) %>%
  addTiles()%>%  
  addMarkers(data=dat,lng=~Longitude, lat=~Latitude)
htmlLeafletOSMParadasL1196
saveWidget(htmlLeafletOSMParadasL1196, file="web/maps/leafletOSMParadasL1196.html")

######################################
# Información extra a los marcadores
# Cargamos datos desde fichero fullData
colnames(fullData)
head(fullData)

#Para no representar todos, cojo una muestra de 100:
#Para los múltiples popup utilizamos la función paste separando las líneas por el 
#retorno de carro en HTML: https://stackoverflow.com/questions/31562383/using-leaflet-library-to-output-multiple-popup-values
htmlLeafletOSMPobGastoOper <- leaflet(data=fullData[sample(nrow(fullData),100),]) %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addMarkers(lng=~Latitude,
             lat=~Longitude,
             popup=~paste0("Nombre parada: ", Nombre_de_, "<br>",
                           "Municipio:     ", Municipio, "(", COD_INE, ")<br>",
                           "Operador:      ", Operador, "<br>",
                           "Línea:         ", Nombre_d_1, "<br>",
                           "Trayecto:      ", Descripcio, "<br>",
                           "Gasto tp.pub:  ", Gasto_tra_pub, "<br>",
                           "Gasto compra veh:", Gasto_vehiculo, "<br>",
                           "Gasto uso veh.pers:", Gasto_uso_veh_pers, "<br>"))
htmlLeafletOSMPobGastoOper

#Plot de popup con leafpop
pt = data.frame(x = 174.764474, y = -36.877245)
pt = st_as_sf(pt, coords = c("x", "y"), crs = 4326)
p2 = lattice::levelplot(t(volcano), col.regions = terrain.colors(100))
leaflet() %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addCircleMarkers(data = pt, group = "pt") %>%
  leafpop::addPopupGraphs(list(p2), group="pt", width = 300, height = 400)
#popup= leafpop::popupGraph(asdf, width = 300, height = 400))

#install.packages("leafpop")

htmlLeafletOSMPobGastoOper
saveWidget(htmlLeafletOSMPobGastoOper, file="web/maps/leafletOSMPobGastoOper.html")


