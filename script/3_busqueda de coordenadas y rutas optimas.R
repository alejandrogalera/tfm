# Búsquda de coordendas
# con OpenStreetMaps (google MAps tiene una API en la que hy que registrarse qe también permite búsqueda de rutas)

library(tmaptools) ## es esta la que se necesita

objetivo<-"Facultad de Estudios Estadísticos, Madrid"
geo_output<-geocode_OSM(objetivo, details=TRUE, return.first.only = TRUE, as.data.frame = T )

laty=geo_output$lat
lonx=geo_output$lon

library(leaflet)
library(sp)
leaflet(data.frame(lonx,laty)) %>% 
  addTiles() %>% 
  addMarkers(lng=~lonx, lat=~laty)


#Al revés si tengo una localización laty=40.4, lonx=-3.74, puedo encontrar la dirección

rev_geocode_OSM(x=lonx, y=laty)


# El paquete OSRM rCarto permite utilizar rutas óptimas utilizando OpenStreetMap
library(osrm)

destino<-"Facultad Comercio y Turismo, Madrid"
geo_output<-geocode_OSM(destino, details=TRUE, return.first.only = TRUE, as.data.frame = T )


laty_destino=geo_output$lat
lonx_destino=geo_output$lon

leaflet(data.frame(c(lonx,lonx_destino),c(laty,laty_destino))) %>% 
  addTiles() %>% 
  addMarkers(lng=~c(lonx,lonx_destino), lat=~c(laty, laty_destino))


ruta<-osrmRoute(src= c(lonx,laty), dst = c(lonx_destino, laty_destino), returnclass = "sp" , overview =  "full")

#proporciona el tiempo en minutos y la distancia en kilómetros
ruta@data


# Ahora podemos añadirlo al leafleat
leaflet(ruta) %>% 
  addTiles() %>%
  addMarkers(lng=~lonx, lat=~laty) %>% 
  addPolylines(color="red",label = (paste0(ruta@data$duration, " minutos, ", ruta@data$distance, " kms")))


#Pregunta 9 evaluación.
datos_map<-data.frame(longx=c(-3.741274,-3.718765,-3.707027,-3.737117, -3.674605,-3.709559 ),
                      laty=c(40.38479, 40.36751, 40.45495,40.44672, 40.50615, 40.42059))
leaflet(data=datos_map) %>%
  addTiles()%>%  
  addMarkers(data=datos_map,lng=~longx, lat=~laty)
