
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
paradasL0242 <- paradasLineasNoDup[paradasLineasNoDup$Nombre_d_1==paradasLineasNoDup$Nombre_d_1[1],]

#Vilafranca - El Vendrell -Tarragona -Port Aventura. Autocars del Penedés
paradasL0808 <- paradasLineasNoDup[paradasLineasNoDup$Nombre_d_1=="L0808",]
write.csv(paradasL0808, file = "data/r/paradasL0808.csv")

dat <- data.frame(Longitude = paradasL0242$Longitude,
                  Latitude = paradasL0242$Latitude)

htmlLeafletOSMParadasL0242 <- leaflet(data=dat) %>%
  addTiles()%>%  
  addMarkers(data=dat,lng=~Longitude, lat=~Latitude)
htmlLeafletOSMParadasL0242
saveWidget(htmlLeafletOSMParadasL0242, file="web/maps/leafletOSMParadasL0242.html")

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
                           "
                           <div class=\"tab\">
  <button class=\"tablinks\" onclick=\"openCity(event, 'London')\">London</button>
  <button class=\"tablinks\" onclick=\"openCity(event, 'Paris')\">Paris</button>
</div>
                           <div id=\"London\" class=\"tabcontent\">
  <h3>London</h3>
  <p>London is the capital city of England.</p>
  <p>London is the capital city of England.</p>
</div>
<div id=\"Paris\" class=\"tabcontent\">
  <h3>Paris</h3>
  <p>Paris is the capital of France.</p>
  <p>Paris is the capital of France.</p>
</div>
"
                          ))
#La documentación para el popup
#https://www.w3schools.com/howto/howto_js_tabs.asp


#Ejemplo de gráfico en el popup
#https://stackoverflow.com/questions/32352539/plotting-barchart-in-popup-using-leaflet-library
colnames(fullData)
a <- fullData[1,]
asdf <- barplot(c(a$Gasto_vehiculo, a$Gasto_tra_pub, a$Gasto_uso_veh_pers, a$Gasto_total),
        main = "Gastos en el sector Transporte",
        names.arg = c("Adq. veh.", "Uso pers. veh.", "Tr. publico", "Total"),
        xlab = "Gasto promedio por familia y tipo de municipio (pob)",
        ylab = "Euros anuales")

png(filename = "test.png")
asdf
dev.off()

kk <- plot(c(1,2,3), c(5,6,7))

leaflet(data=fullData[sample(nrow(fullData),100),]) %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addMarkers(lng=~Latitude,
             lat=~Longitude,
             popup= leafpop::popupGraph(kk, width = 300, height = 400))
             #popup= leafpop::popupGraph(asdf, width = 300, height = 400))

#https://rdrr.io/github/r-spatial/leafpop/man/addPopupGraphs.html
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


