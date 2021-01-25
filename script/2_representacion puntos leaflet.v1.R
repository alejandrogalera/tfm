# librería leaflet

library(leaflet) #Mapas web interactivos.


library(sp)
library(rgdal)


CCAA_MAP<-readOGR("3.EstudioR/cartoclase","CCAA_SALARIOS")
summary(CCAA_MAP)

#Hay que indicar la cartografía y los polígonos. En concreto, esta gráfica se rellena
#con los cuantiles y los colores que van desde amarillo al marrón pasando por el naranja, en 9 pasos.
leaflet(CCAA_MAP,options = leafletOptions(attributionControl = FALSE)) %>%
  addPolygons(data=CCAA_MAP, stroke=TRUE, opacity = 0.5, fillOpacity = 0.7,color="grey10",
              fillColor = ~colorQuantile("YlOrBr", n=9, SALARIO, na.color = "white")(SALARIO))

#Permite añadir la capa del OpenStreetMap
leaflet(CCAA_MAP,options = leafletOptions(attributionControl = FALSE)) %>%
  addTiles()%>%
  addPolygons(data=CCAA_MAP, stroke=TRUE, color="grey10")

#Se le puede añadir distinto grado de opacidad.  
leaflet(CCAA_MAP,options = leafletOptions(attributionControl = FALSE)) %>%
  addTiles()%>%
  addPolygons(data=CCAA_MAP, stroke=TRUE, opacity = 0.25, fillOpacity = 0.27,color="grey10",
              fillColor = ~colorQuantile("YlOrBr", n=9, SALARIO, na.color = "white")(SALARIO))
#Se le puede dar a Export en el menú de gráficas -> Save as web page.
#Este mapa utiliza una proyección mercator, que está muy bien para zonas cercanas al ecuador, pero 
#los polos muy distorsionados.

# Para situar marcadores
#Es decir, representar puntos.
datos_map<-data.frame(longx=c(-3.741274,-3.718765,-3.707027, -3.674605,-3.709559 ),
                      laty=c(40.38479, 40.36751, 40.45495, 40.50615, 40.42059))

leaflet(data=datos_map) %>%
  addTiles()%>%  
  addMarkers(data=datos_map,lng=~longx, lat=~laty)

#Se le podría asignar más información a los marcadores.

# Cargamos datos desde fichero 
Datos <- read.csv(file="3.EstudioR/cartoclase/Data_Housing_Madrid.csv",header=TRUE)

hist(Datos$house.price)

#Para no representar todos, cojo una muestra de 100:
m <- leaflet(data=Datos[sample(nrow(Datos),100),]) %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addMarkers(lng=~longitude,
             lat=~latitude,
             popup=~paste0(type.house, " - ", house.price, " euros"))
#Basta con añadir en el popup el tipo de la casa y el precio a la función addMarkers.
m  # Print the map



