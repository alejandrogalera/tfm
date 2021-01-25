# Importar Cartograf??as a R

# existen diferentes sitios donde descargar cartograf??as
# La uni??n europea
# https://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units/nuts
# Instituto geogr??fico Nacional
# https://www.ign.es/web/cbg-area-cartografia
# El INE (proporciona informaci??n a nivel de distrito Censal)

options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")


# 1 Lectura de Shapes ----

library(sp) #Datos espaciales
library(rgdal) #Leer cartograf??as.
library(rgeos)
library(maptools) #Tambi??n permite leer cartograf??as

# dir() para encontrar el nombre del dirctorio donde est??n guardados los
# ficheros shape con las cartograf??as
dir()

# puedo llamar dir() con el nombre del directorio

dir("1.AnalisisParadas")
# Read in shapefile with readOGR(): neighborhoods
paradasCat<-readOGR("1.AnalisisParadas","PARADAS_DEFINITIVO")
#Crea un Large SpatialPolygonsDataFrame: tiene tantas filas como pol??gonos: 17 CCAA + 2 ciudades aut??nomas.

dir("notebooks/BTN100_TEMA6_TRANSPORTES")
carrAutovia<-readOGR("notebooks/BTN100_TEMA6_TRANSPORTES", "BTN100_0601L_AUTOVIA")
carrAutopista<-readOGR("notebooks/BTN100_TEMA6_TRANSPORTES", "BTN100_0602L_AUTOPISTA")
carrNac<-readOGR("notebooks/BTN100_TEMA6_TRANSPORTES", "BTN100_0603L_CARR_NAC")
carrAuton<-readOGR("notebooks/BTN100_TEMA6_TRANSPORTES", "BTN100_0604L_CARR_AUTON")

dir("Carto_BCN500")
poblacion<-readOGR("Carto_BCN500", "BCN500_0501P_POBLACION")
prov<-readOGR("Carto_BCN500", "BCN500_0103L_EV_ENCLAVE_PROV")  #readOGR descarga la dimensi??n Z.
libAdm<-readOGR("Carto_BCN500", "BCN500_0101S_LIMITE_ADM")

#Si el directorio es el de trabajo tambi??n se puede usar
#CCAA_MAP<-readOGR(dsn=getwd(),"CCAA_GEO_ETRS89")
#CCAA_MAP<-readOGR(dsn="."","CCAA_GEO_ETRS89")
CCAA_MAP<-readOGR("3.EstudioR/cartoclase", "CCAA_GEO_ETRS89")
summary(CCAA_MAP)
#De la p??gina https://www.ine.es/daco/daco42/codmun/cod_ccaa.htm vemos que el c??digo de Catalu??a es 09
catCodeId <- 9
catCode <- sprintf("CA%02d",catCodeId)
catalunyaMap<-CCAA_MAP
catCode
catalunyaMap@data<-CCAA_MAP@data[CCAA_MAP@data$cod_CCAA==catCode,]
catalunyaMap@polygons <- CCAA_MAP@polygons[catCodeId]
# summary() del Mapa
summary(paradasCat)

#Dibujo preliminar de las paradas
plot(paradasCat)

#De aqu?? en adelante redibujaremos las gr??ficas con la librer??a tmap
library(tmap)

tm_shape(catalunyaMap)+
  tm_borders()+
  tm_shape(paradasCat)+
  tm_dots(title = "paradas", col = 'blue', size = 0.01)
#Vemos c??mo las l??neas de autobuses catalanas disponen de paradas ligeramente fuera del territorio auton??mico.
#No obstante, es recomendable comprobar que se ha utilizado la misma proyecci??n para todas las gr??ficas
#superpuestas con tm_shape.
proj4string(paradasCat)
proj4string(catalunyaMap)
#No se trata de la misma proyecci??n, ya que una utiliza una elipse WGS84 y la otra GRS80.

#El siguiente paso es, por tanto tratar de cambiar a un mismo sistema de referencia.
#Hay muchas opciones definidas en el EPSG se pueden sacar de  http://spatialreference
#Por ejemplo, la n??mero 14 usa ETRS89 con el huso horario 0:
# 14	EPSG:4258	Geogr??ficas en ETRS89	HUSO 0	DATUM ETRS89
CRS.new <- CRS("+init=epsg:4258") #Sistema de referencia Final

paradasCat2 <- spTransform(paradasCat, CRS.new)  
catalunyaMap2 <- spTransform(catalunyaMap, CRS.new)
#Este ??ltimo comando devuelve un error en spTransform sin dar demasiada informaci??n.
## Error in SpatialPolygons(output, pO = slot(x, "plotOrder"), proj4string = CRSobj) : 
##   length(pO) == length(Srl) is not TRUE

#La recomendaci??n de la comunidad StackOverflow para esta situaci??n es transformar 
#las coordenadas de cada Polygon a SpatialPoints y luego aplicar el CRS para convertir
#a WGS84.
#Es por ello que se define la siguiente funci??n convertProjGRS80toWGS84

#La funci??n tiene la siguiente estructura.
#  @data
#    $ SP_ID
#    $ id
#    $ cod_CCAA
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

catalunyaMap2 <- convertProjGRS80toWGS84(catalunyaMap, proj4string(paradasCat))

#Tienen distinta proyecci??n, por lo que hay que unificar.
proj4string(paradasCat)
# "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
proj4string(catalunyaMap2)
#Antigua proyecci??n: "+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs"
#Nueva proyecci??n: "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"

#Volvemos a aplicar la transformada de projecci??n spTransform
paradasCat2 <- spTransform(paradasCat, CRS.new)  
catalunyaMap2 <- spTransform(catalunyaMap, CRS.new)
#Obteniendo el mismo error a pesar de partir de la misma proyecci??n.
#Lo representamos pero aun as?? habr?? que buscar posteriormente un mapa del borde de la comunidad que sea
#compatible con las funciones de la librer??a sp como spTransform.

tm_shape(catalunyaMap2)+
  tm_borders()+
  tm_shape(paradasCat)+
  tm_dots(title = "paradas", col = 'blue', size = 0.01)


#Pasamos a probar con un ETRS80 UTM 30N provincial de ArcGIS
dir("Carto_RPubs_provincias")
provincias<-readOGR("Carto_RPubs_provincias", "Provincias_ETRS89_30N")

#Convertimos a la proyecci??n com??n que se encuentra el mapa de paradas.
provincias <- spTransform(provincias, CRS.new)

#El mapa provincias contiene todas las provincias de Espa??a, pero s??lo queremos las de una comunidad aut??noma.
#Es por ello que se define la funci??n getArcGISRegionProvinces especific??ndole el dataset formado con el 
#fichero provincias y el c??digo de la regi??n en formato entero.

#regionCodeId es el c??digo de la comunidad aut??noma seg??n la base de datos del Instituto Nacional de 
#Estad??sticas INEbase
getArcGISRegionProvinces <- function(shapemap, regionCodeId)
{
  #Dado que regionCode es un int, hay que pasarlo a string.
  regionCode <- sprintf("%02d",regionCodeId)
  temp <- shapemap
  temp@data[temp@data$Cod_CCAA==regionCode,]
  codigosProv <- temp@data[temp@data$Cod_CCAA==regionCode,]$Codigo
  l <- length(temp@polygons)
  #Nos quedamos con los pol??gonos relativos a los ??ndices de las provincias
  #seleccionadas.
  temp@polygons <- temp@polygons[codigosProv]

  return(temp)
}

#catCodeId = 9
catalunyaMap3 <- getArcGISRegionProvinces(provincias, catCodeId)

tm_shape(catalunyaMap3)+
  tm_borders()+
  tm_shape(paradasCat)+
  tm_dots(title = "paradas", col = 'purple', size = 0.01)

#El siguiente paso es representar las carreteras.

# Representaci??n de las carreteras seg??n los ficheros del Instituto Geogr??fico Nacional.
#Para esta representaci??n es necesario filtrar las carreteras, ya que los ficheros .shp vienen para toda Espa??a.
#Habr?? que estudiar el filtrado de las carreteras por la zona catalana en 
#https://stackoverflow.com/questions/17571602/r-filter-coordinates
#Vamos a realizar un encuadre de la comunidad aut??noma a partir de los valores m??nimos y m??ximos de latitud 
#y longitud de las paradas, el cual tomamos a grosso modo del encuadre de Catalu??a.
latMin<-40.4
longMin<-0.11
latMax<-42.9
longMax<-3.34

#Los ficheros shape vienen con las coordenadas seg??n la siguiente estructura:
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

#Se podr??a buscar por la etiqueta de carrNac@data$ETIQUETA para filtrar por comunidades, pero no ser??a 
#v??lido para las autov??as y autopistas que atraviesan comunidades, por ejemplo. Por eso es m??s efectivo
#el filtrado por coordenadas.
carrAutopistaCat <- filterWGS84ShapeLines(carrAutopista, latMin, latMax, longMin, longMax) 
carrAutoviaCat <- filterWGS84ShapeLines(carrAutovia, latMin, latMax, longMin, longMax)
carrNacCat <- filterWGS84ShapeLines(carrNac, latMin, latMax, longMin, longMax)
carrAutonCat <- filterWGS84ShapeLines(carrAuton, latMin, latMax, longMin, longMax)



##UNIT TEST
res <- carrAuton
cat("Linea ",as.character(res@lines[[56729]]@ID),"\n")
temp <- res@lines[[56729]]@Lines[[1]]@coords
cat("head: ",as.character(res@lines[[56729]]@Lines[[1]]@coords),"\n")
if (length(temp)==0) {
  cat("Next\n")
  removeData <- c(removeData, i) 
  res@lines[[i]]@Lines[[1]]@coords <- temp
  next
}
cat("iter longmin\n")
longMin
temp2<- temp[temp[,1]>longMin,]
temp2
cat("head: ",as.character(temp),"\n")
#Si debido al filtrado se han borrado todos los elementos marcamos para borrar
if (length(temp)<=1) {
  cat("Next\n")
  removeData <- c(removeData, i) 
  res@lines[[i]]@Lines[[1]]@coords <- temp
  next
}
#https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r
###Error in (function (cl, name, valueClass)  : 
###            assignment of an object of class ???NULL??? is not valid for @???coords??? in an object of class ???Line???; is(value, "matrix") is not TRUE 
#https://stackoverflow.com/questions/21585721/how-to-create-an-empty-matrix-in-r

temp3<- tryCatch({ temp2[temp2[,1]<longMax,] },
    error=function(cond) { return(NULL) })
temp <- matrix(, nrow = 0, ncol = 2)
save.image("backup.RData")
tm_shape(catalunyaMap4)+
  tm_borders()+
  tm_shape(carrAutopistaCat)+tm_lines(col='blue', size=0.02)+
  tm_shape(carrAutoviaCat)+tm_lines(col='green', size=0.02)+
  tm_shape(carrNacCat)+tm_lines(col='brown', size=0.02)+
  tm_shape(carrAutonCat)+tm_lines(col='orange', size=0.008)
save.image("backup.RData")

#Pasamos a leer un rds para los c??lculos por municipio (nivel 4: ESP_4)
library(sp)
library(rgdal)
dir("Carto_GADM")
ESP <- readRDS("Carto_GADM/gadm36_ESP_4_sp.rds")
unique(ESP$NAME_1)
catalunyaMap3 <- ESP[ESP$NAME_1=="Catalu??a",]
spplot(catalunyaMap3, "NAME_2")
catalunyaMap3@proj4string
ESP@proj4string

spplot(catalunyaMap3, "NAME_3")






















# Voy a cargar alg??n dato
# me descargo desde el INE datos de SALARIOS

#Cuidado. Antes de cargar los datos hay que verificar que est?? en el mismo UTF-8 o de lo 
#contrario, las ?? o caracteres desconocidos se tomar??n como err??neos y se cortar?? el proceso
#de lectura de read.csv.
salarios<-read.csv("datos_CCAA/SALARIOS.csv",sep = ";")
summary(salarios)

library(dplyr)
CCAA_MAP@data<-dplyr::left_join(CCAA_MAP@data,salarios, by=c("cod_CCAA"="COD_CCAA"))
View(CCAA_MAP@data)

#o tambien con sp::spCbind(CCAA_MAP@data, tablanewdatos) los rownames deben ser los mismos
rownames(CCAA_MAP@data)


# Ahora puedo hacer alg??n dibujo de mapa algo m??s bonito
library(tmap)
tm_shape(CCAA_MAP) +
  tm_borders() +
  tm_fill(col = "SALARIO")

# Ahora puedo Grabar mi nueva cartograf??a con writeOGR de la librer??a rgdal.
#Tengo que darle un nuevo nombre: CCAA_SALARIOS
writeOGR(obj=CCAA_MAP, dsn="cartograf??as", layer="CCAA_SALARIOS", driver="ESRI Shapefile") 



####### VOY A LEER OTRA CARTOGRAFIA
library(rgdal)


Munic_ESP<- rgdal::readOGR(dsn="cartograf??as",layer="Munic04_ESP_GEO_ETRS89_DAT")
View(Munic_ESP@data)

# otras librer??as que permiten leer shapes
# library(maptools)
# Munic_ESP<- maptools::readShapeSpatial("Munics04_GEO_ETRS89_DAT.shp",IDvar = "cod_ine", proj4string=CRS("+init=epsg:4326")) # Comprado al INE

proj4string(Munic_ESP)
proj4string(CCAA_MAP)


library(tmap)
tm_shape(CCAA_MAP) +
  tm_borders() +
  tm_shape(Munic_ESP)+
  tm_borders(col = "gray85")+
  tm_fill(col="PrecioIn16")
#Sin los bordes se ve mejor.
tm_shape(CCAA_MAP) +
  tm_borders() +
  tm_shape(Munic_ESP)+
  tm_fill(col="PrecioIn16")

####
# Sistmas de proyecci??n
#  1	EPSG:4230	Geogr??ficas en ED 50	HUSO 0	DATUM ED50
#  2	EPSG:4326	Geogr??ficas en WGS 84 (Cat dice que es WGS80, pero el SRS es WGS84)	HUSO 0	DATUM WGS84
#  3	EPSG:32627	UTM huso 27N en WGS 84	HUSO 27	DATUM WGS84	
#  4	EPSG:32628	UTM huso 28N en WGS 84	HUSO 28	DATUM WGS84
#  5	EPSG:32629	UTM huso 29N en WGS 84	HUSO 29	DATUM WGS84	
#  6	EPSG:32630	UTM huso 30N en WGS 84	HUSO 30	DATUM WGS84	
#  7	EPSG:32631	UTM huso 31N en WGS 84	HUSO 31	DATUM WGS84	
#  8	EPSG:23029	UTM huso 29N en ED50	HUSO 29	DATUM ED50	
#  9	EPSG:23030	UTM huso 30N en ED50	HUSO 30	DATUM ED50	
# 10	EPSG:23031	UTM huso 31N en ED50	HUSO 31	DATUM ED50	
# 11	EPSG:25829	UTM huso 29 en ETRS89	HUSO 29	DATUM ETRS89	
# 12	EPSG:25830	UTM huso 30 en ETRS89	HUSO 30	DATUM ETRS89	
# 13	EPSG:25831	UTM huso 31 en ETRS89	HUSO 31	DATUM ETRS89	
# 14	EPSG:4258	Geogr?ficas en ETRS89	HUSO 0	DATUM ETRS89


# Para conocer exactamente los par?metros de cada proyecci?n con el EPSG se pueden sacar de  http://spatialreference

#Por ejemplo:

#  http://spatialreference.org/ref/epsg/23030/proj4/ 
#  +proj=utm +zone=30 +ellps=intl +units=m +no_defs   



#Para unir cartograf??as
map_cpTOT<-spRbind(map_1, map_2)


#Para Cambiar el sistema de referencias
library(rgdal)  
CRS.new <- CRS("+init=epsg:4258") #Sistema de referencia Final
Munic_ESP <- spTransform(Munic_ESP, CRS.new)  


#Para sacar los pol?gonos de las Provincias (tambi?n vldr?a para sacar los de las diferentes agrupaciones)
MAPA_PROV<- unionSpatialPolygons(Munic_ESP, IDs=Munic_ESP$COD_PROV)
plot(MAPA_PROV)



# PARA ENCONTRAR A QUE pol??gono pertenece
id_polygoncp <- over(DATOSGEO,as(mapa,"SpatialPolygons"))

# PARA unir dos cartograf??as (OJO con identificadores de pol??gono diferente)
#Ahora utilizo spRbind para unir los dos spatialdataframes
map_cpTOT<-spRbind(map_cpAcoruna3, map_cpLugo3)
