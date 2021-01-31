#Estudio y procesado de los dataset (shape) del IGN (Instituto Geográfico Nacional)
options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")

library(sp)       # Datos espaciales
library(rgdal)    # Lectura de cartografías
library(rgeos)    # Lectura de cartografías
library(maptools) # Lectura de cartografías
library(tmap)     # Representación gráfica de shapes

# Utilizamos los shapes que disponemos en el directorio del Instituto Geográfico Nacional.
#Leemos el shape con readOGR
dir("data/ign/BTN100_TEMA6_TRANSPORTES")
carrAutovia<-readOGR("data/ign/BTN100_TEMA6_TRANSPORTES", "BTN100_0601L_AUTOVIA")
carrAutopista<-readOGR("data/ign/BTN100_TEMA6_TRANSPORTES", "BTN100_0602L_AUTOPISTA")
carrNac<-readOGR("data/ign/BTN100_TEMA6_TRANSPORTES", "BTN100_0603L_CARR_NAC")
carrAuton<-readOGR("data/ign/BTN100_TEMA6_TRANSPORTES", "BTN100_0604L_CARR_AUTON")

#Se puede acceder al mapa de los límites 
#mapDir <- "data/ign/SIGLIM_Publico_INSPIRE/SHP_ETRS89/recintos_municipales_inspire_peninbal_etrs89"

#Buscamos un borde provincial sobre el que dibujar las carreteras.
#catalunyaIGNMap<- readOGR(mapDir, "recintos_provinciales_inspire_peninbal_etrs89")
mapDir <- "data/ign/lim_CCAA"
catalunyaIGNMap<- rgdal::readOGR(mapDir, "recintos_provinciales_inspire_peninbal_etrs89")
tm_shape(catalunyaIGNMap)+
  tm_borders()

#Otra opción es cargar un mapa análogo de la web de ArcGIS: https://www.arcgis.com/home/item.html?id=83d81d9336c745fd839465beab885ab7
mapDirArcGIS <- "data/arcgis/Provincias_ETRS_1989_UTM_Zone_30N"
catalunyaArcGISMap<- rgdal::readOGR(mapDirArcGIS, "Provincias_ETRS89_30N")
tm_shape(catalunyaArcGISMap)+
  tm_borders()
#Este mapa de ArcGIS incluye incluso las islas Canarias.

#Tenemos un mapa de toda España, y nos interesaría tenerlo sólo de Cataluña para representar las carreteras
#con una mayor resolución centrado en la región en estudio.

#Antes que nada analicemos la proyección.
proj4string(catalunyaIGNMap)
proj4string(catalunyaArcGISMap)
#Ambos tienen un mapa similar con una proyección elipsoidal GRS80.
"+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs"
"+proj=utm +zone=30 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#Sin embargo, la proyección de las carreteras es diferente: WGS84
proj4string(carrAutovia)
#"+proj=longlat +ellps=WGS84 +no_defs"
#Esto indica que será necesario convertir los shapes a una única proyección y así evitar errores tales como
#que una parada de autobús o cualquier otro dato que incorporemos esté desplazada en el mapa o con respecto 
#a las carreteras.

#Estudio de conversión de proyección.
#Hemos visto que tenemos dos shapes con distinta proyección, utilizando uno una elipse WGS84 y el otro GRS80.
#El siguiente paso es, por tanto tratar de cambiar a un mismo sistema de referencia.
#Hay muchas opciones definidas en el EPSG se pueden sacar de  http://spatialreference
#Por ejemplo, la número 14 usa ETRS89 con el huso horario 0:
# 14	EPSG:4258	Geográficas en ETRS89	HUSO 0	DATUM ETRS89
CRS.new <- CRS("+init=epsg:4258") #Sistema de referencia Final

carrAutovia <- spTransform(carrAutovia, CRS.new)  
carrAutopista <- spTransform(carrAutopista, CRS.new)  
carrNac <- spTransform(carrNac, CRS.new)  
carrAuton <- spTransform(carrAuton, CRS.new)  

catalunyaIGNMap <- spTransform(catalunyaIGNMap, CRS.new)
catalunyaArcGISMap <- spTransform(catalunyaArcGISMap, CRS.new)

#Ya tenemos el mapa autonómico, provincial y las carreteras transformadas a la misma proyección.
#Sin embargo, debemos seguir teniendo presente que el mapa provincias contiene todas las provincias de 
#España, pero solo requerimos las de una comunidad autónoma para el estudio.
#Es por ello que se define la función getArcGISRegionProvinces especificándole el dataset formado con el 
#fichero provincias y el código de la región en formato entero.

#Aunque tanto catalunyaIGNMap como catalunyaArcGISMap son mapas aceptables para representar las carreteras
#y tienen la misma proyección llegados a este punto, ambos poseen parámetros diferentes en la sección @data.
#catalunyaArcGISMap tiene Código, Texto, Texto alternativo (nombre de la provincia), Cod_CCAA y CCAA (nombre
#de la comunidad autónoma)

#Según el INE, los códigos de CCAA y provincia vienen recogidos en la siguiente tabla:
#https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm
#Fuente: INE: Relación de provincias por comunidades autónomas y sus códigos
regionCodeId = 9
#Cataluña tiene el Cod_CCAA = 9

#Aunque sólo se va a invocar una vez para el estudio, es buena práctica definir una función para reutilizar
#código en futuras llamadas.
getArcGISRegionProvinces <- function(shapemap, regionCodeId)
{
  #Dado que regionCode es un int, hay que pasarlo a string.
  regionCode <- sprintf("%02d",regionCodeId)
  temp <- shapemap
  temp@data[temp@data$Cod_CCAA==regionCode,]
  codigosProv <- temp@data[temp@data$Cod_CCAA==regionCode,]$Codigo
  l <- length(temp@polygons)
  #Nos quedamos con los polígonos relativos a los índices de las provincias
  #seleccionadas.
  temp@polygons <- temp@polygons[codigosProv]
  
  return(temp)
}

#catCodeId = 9
catalunyaMap <- getArcGISRegionProvinces(catalunyaArcGISMap, regionCodeId)
catalunyaMap@data <- dplyr::filter(catalunyaMap@data, catalunyaMap@data$CCAA=="Cataluña")

tm_shape(catalunyaMap)+
  tm_borders()

rgdal::writeOGR(catalunyaMap, "data/arcgis/new", "Prov_Cat_Map_ESR89", 
                driver = "ESRI Shapefile", encoding = "UTF-8")


#El siguiente paso es representar las carreteras.

# Representación de las carreteras según los ficheros del Instituto Geográfico Nacional.
#Para esta representación es necesario filtrar las carreteras, ya que los ficheros .shp vienen para toda España.
#Habrá que estudiar el filtrado de las carreteras por la zona catalana en 
#https://stackoverflow.com/questions/17571602/r-filter-coordinates
#Vamos a realizar un encuadre de la comunidad autónoma a partir de los valores mínimos y máximos de latitud 
#y longitud de las provincias, el cual podríamos permitirnos tomar a grosso modo del encuadre de Cataluña.

#https://stackoverflow.com/questions/62540311/calculate-longitudinal-and-latitudinal-range-of-a-polygon-in-r
getMaxMinDataframeFromShape <- function(shpDir, shpFile)
{
  #Esta función usa los métodos de la librería sf
  fullFilename <- paste( gsub("/$", "", shpDir), "/", shpFile, sep = "")
  #La ruta absoluta es válida tanto si shpDir tiene barra al final como si no.
  
  nc = sf::st_read(dsn=fullFilename)
  #Se podría plotear la representación del shape nc con la misma st_geometry
  #par(mar = rep(0,4))
  #plot(sf::st_geometry(nc))
  res <- as.data.frame(do.call("rbind", lapply(sf::st_geometry(nc), st_bbox)))
  
  #Ahora que tenemos los máximos y mínimos de cada polígono de la forma:
  #       xmin     ymin     xmax     ymax
  #1 1.3599764 41.19562 2.778727 42.32329
  #2 1.7246327 41.64881 3.332624 42.49538
  #3 0.3203399 41.27412 1.855420 42.86138
  #4 0.1591816 40.52292 1.653502 41.58257
  #Queda calcular el mínimo de las columnas min y el máximo de las max, para
  #terminar devolviendo un único vector.
  res <- cbind(min(res[1]), min(res[2]), max(res[3]), max(res[4]))
  colnames(res) <- c("longMin", "latMin", "longMax", "latMax")  
  #Pasamos a dataframe para acceder por nombre de variable en lugar de número de 
  #columna
  return(as.data.frame(res))
}                                        

limits <- getMaxMinDataframeFromShape("data/arcgis/new", "Prov_Cat_Map_ESR89.shp")

latMin <-limits$latMin
longMin<-limits$longMin
latMax <-limits$latMax
longMax<-limits$longMax


#Los ficheros shape de las carreteras vienen con las coordenadas según la siguiente estructura:
# @data (data.frame)
#   $ID (identificador de la carretera)
#   $ID_CODIGO
#   $FECHA_ALTA
#   ...
#   $ETIQUETA: "A-40", "A-43",...
# @lines
#   $ class Lines (lista de 1)
#      @Lines
#         $ class Line
#            @coords
filterWGS84ShapeLines <- function(shapefile, latMin, latMax, longMin, longMax) 
{
  res <- shapefile
  l <- length(shapefile@lines)
  removeData <- c()
  
  for (i in seq(1,l))
  {
    cat("Linea ",as.character(res@lines[[i]]@ID),"\n")
    temp <- res@lines[[i]]@Lines[[1]]@coords
    #cat("head: ",as.character(res@lines[[i]]@Lines[[1]]@coords),"\n")
    
    if (length(temp)<=1) {
      #cat("Next\n")
      removeData <- c(removeData, i) 
      res@lines[[i]]@Lines[[1]]@coords <- temp
      next
    }
    #cat("iter longmin\n")
    #temp<- temp[temp[,1]>longMin,]
    temp<- tryCatch({ temp[temp[,1]>longMin,] },
                     error=function(cond) { return(matrix(, nrow = 0, ncol = 2)) })
    #Si debido al filtrado se han borrado todos los elementos marcamos para borrar
    if (length(temp)<=1) {
      #cat("Next\n")
      removeData <- c(removeData, i) 
      res@lines[[i]]@Lines[[1]]@coords <- temp
      next
    }
    #cat("iter longmax\n")
    #temp<- temp[temp[,1]<longMax,]
    temp<- tryCatch({ temp[temp[,1]<longMax,] },
                    error=function(cond) { return(matrix(, nrow = 0, ncol = 2)) })
    #Si debido al filtrado se han borrado todos los elementos marcamos para borrar
    if (length(temp)<=1) {
      #cat("Next\n")
      removeData <- c(removeData, i) 
      res@lines[[i]]@Lines[[1]]@coords <- temp
      next
    }
    #cat("iter latmin\n")
    #temp<- temp[temp[,2]>latMin,]
    temp<- tryCatch({ temp[temp[,2]>latMin,] },
                    error=function(cond) { return(matrix(, nrow = 0, ncol = 2)) })
    
    #Si debido al filtrado se han borrado todos los elementos marcamos para borrar
    if (length(temp)<=1) {
      #cat("Next\n")
      removeData <- c(removeData, i)
      res@lines[[i]]@Lines[[1]]@coords <- temp
      next
    }
    
    #cat("iter latmax\n")
    #temp<- temp[temp[,2]<latMax,]
    temp<- tryCatch({ temp[temp[,2]<latMax,] },
                    error=function(cond) { return(matrix(, nrow = 0, ncol = 2)) })
    
    #Si debido al filtrado se han borrado todos los elementos marcamos para borrar
    if (length(temp)<=1) {
      #cat("Next\n")
      removeData <- c(removeData, i) 
      res@lines[[i]]@Lines[[1]]@coords <- temp
      next
    }
    
  }
##DOC
  #https://stackoverflow.com/questions/53126854/conditionally-removing-rows-from-a-matrix-in-r
  #vals <- vals[vals[, 1] >= 10, ]
  #https://stackoverflow.com/questions/12328056/how-do-i-delete-rows-in-a-data-frame
  
  res@lines <- res@lines[-removeData]
  res@data <- res@data[-removeData,]
  
  return(res)
}

#Se podría buscar por la etiqueta de carrNac@data$ETIQUETA para filtrar por comunidades, pero no sería 
#válido para las autovías y autopistas que atraviesan comunidades, por ejemplo. 
#Por eso es más efectivo el filtrado por coordenadas.
carrAutopistaCat <- filterWGS84ShapeLines(carrAutopista, latMin, latMax, longMin, longMax) 
carrAutoviaCat <- filterWGS84ShapeLines(carrAutovia, latMin, latMax, longMin, longMax)
carrNacCat <- filterWGS84ShapeLines(carrNac, latMin, latMax, longMin, longMax)
carrAutonCat <- filterWGS84ShapeLines(carrAuton, latMin, latMax, longMin, longMax)

#Representamos las gráficas.
tm_shape(catalunyaMap)+
  tm_borders()+
  tm_shape(carrAutopistaCat)+tm_lines(col='blue', scale=2)+
  tm_shape(carrAutoviaCat)+tm_lines(col='green', scale=2)+
  tm_shape(carrNacCat)+tm_lines(col='red', scale=1)+
  tm_shape(carrAutonCat)+tm_lines(col='orange', scale=1)


#Guardamos los datos a fichero.
saveRDS(limits, file = "limits.rds")

rgdal::writeOGR(catalunyaMap, "data/arcgis/new", "Prov_Cat_Map_ESR89", 
                driver = "ESRI Shapefile", encoding = "UTF-8")

rgdal::writeOGR(carrAutoviaCat, "data/ign/new", "carrAutoviaCat", 
                driver = "ESRI Shapefile", encoding = "UTF-8")
rgdal::writeOGR(carrAutopistaCat, "data/ign/new", "carrAutopistaCat", 
                driver = "ESRI Shapefile", encoding = "UTF-8")
rgdal::writeOGR(carrNacCat, "data/ign/new", "carrNacCat", 
                driver = "ESRI Shapefile", encoding = "UTF-8")
rgdal::writeOGR(carrAutonCat, "data/ign/new", "carrAutonCat", 
                driver = "ESRI Shapefile", encoding = "UTF-8")




#Nota troubleshooting: 
#En ocasiones, el spTransform(mapShapeFile, CRS.new) puede devolver un error sin dar más información que 
#la siguiente:
## Error in SpatialPolygons(output, pO = slot(x, "plotOrder"), proj4string = CRSobj) : 
##   length(pO) == length(Srl) is not TRUE

#La recomendación de la comunidad StackOverflow para esta situación es transformar 
#las coordenadas de cada Polygon a SpatialPoints y luego aplicar el CRS para convertir
#a WGS84.
#Es por ello que se define la siguiente función convertProjGRS80toWGS84

#La función tiene la siguiente estructura.
#  @data
#    $ ... parameters
#  @polygons: List of n
#    $Polygons (formal class)
#       @Polygons (list of n)
#          $Polygon
#             @coords
#             @labpt
#             @area
#             @hole
#             @ringDir
#          $Polygon #2
#             ...
#       @plotOrder
#       @labpt
#       @ID
#       @area
#  @plotOrder
#  @bbox
#  @proj4string
#    @proargs: chr "+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs"
convertProjGRS80toWGS84 <- function(origen, projDest)
{
  destino <- origen
  destino@proj4string@projargs <- projDest  #WGS84 proj4 string
  
  l <- length(destino@polygons)
  for (i in seq(1,l)) {
    aux <- destino@polygons[[i]]
    l2 <- length(destino@polygons[[i]]@Polygons)
    for (j in seq(1,l2)) {
      temp <- data.frame(x = destino@polygons[[i]]@Polygons[[j]]@coords[,1], 
                         y = destino@polygons[[i]]@Polygons[[j]]@coords[,2]) 
      temp <- SpatialPoints(temp, proj4string = CRS(proj4string(origen)))
      cord.WGS84 <- spTransform(temp, CRS(projDest))
      
      destino@polygons[[i]]@Polygons[[j]]@coords <- cord.WGS84@coords
    }
  }
  return(destino)
}
