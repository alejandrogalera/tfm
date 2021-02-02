options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")


library(sp)       #Datos espaciales
library(rgdal)    #Lectura de cartografías
library(rgeos)    #Lectura de cartografías
library(maptools) #Lectura de cartografías
library(readxl)   #Lectura de ficheros Excel
library(tmap)     #Representación de funciones
library(stringr)  #Para str_split_fixed

################################
# Análisis de líneas y paradas #
################################
dir("data/opendata_esri/paradas")

download.file("https://opendata.arcgis.com/datasets/01ead513fe9842b98a19dd3e451ce37c_0.csv", 
              "data/opendata_esri/paradas/PARADAS.csv")
download.file("https://opendata.arcgis.com/datasets/01ead513fe9842b98a19dd3e451ce37c_0.zip", 
              "data/opendata_esri/paradas/paradas.shape.zip")
paradasCat<-readOGR("data/opendata_esri/paradas","PARADAS_DEFINITIVO")

load("data/r/catalunyaPoblacMap.RData")

#Usamos una variable provisional para setear el máximo de Barcelona más cerca de la 
#siguiente ciudad con más población y que de este modo no parezcan tan homogéneos en 
#cuanto a color los municipios con poca densidad de habitantes.
catProvisionalParaGraf<-catalunyaPoblacMap
catProvisionalParaGraf$Poblacion[catalunyaPoblacMap$NAME_4=="Barcelona"]<-300000
mipaleta = c("orange1", "red", "green3", "blue", "cyan", "magenta", "yellow","gray", "black")

tm_shape(catProvisionalParaGraf)+
  tm_borders()+
  tm_fill(col = "Poblacion", n=100, palette = mipaleta)+
  tm_shape(paradasCat)+
  tm_dots(title = "paradas", col = 'blue', size = 0.01)+
  tm_layout(main.title= 'Revision del Padron Municipal. Fuente: INE\nParadas de autobuses interurbanos. Fuente: Esri', 
            main.title.size = 1,
            legend.outside = TRUE,
            legend.outside.position = "right",
            legend.width = 1,
            main.title.position = c('left', 'top'))

#Esto es especialmente útil por un lado para evaluar los municipios que no tiene parada y se desea estimar
#si la deberían tener, y por otro lado si las líneas formadas por sucesiones de puntos no deberían comunicar 
#zonas con una mayor densidad de población, o bien ofrecer rutas alternativas en caso de que la zona 
#tenga un número considerable de incidencias de tráfico.

#Analicemos el dataset un poco más en profundidad.
unique(paradasCat@data$Operador)
#Vemos que tenemos paradas de 120 operadores.
#A continuación se ordenarán para estudiar si nuestra empresa debería centrarse en los operadores que disponen
#de más lineas, usan más paradas y por tanto presumiblemente tendrán una flota mayor, o bien debería contemplar 
#las empresas minoritarias (o long tail) para ofrecer un servicio conjunto que optimice sus beneficios, como 
#por ejemplo no compitiendo entre sí por zonas poco pobladas.

######
#Vamos a calcular el número de paradas que tiene cada operador y lo ordenaremos.
#Con esto se podrá ofrecer un servicio de análisis de la competencia centralizado.

#En primer lugar, contamos los NA en el nombre de la parada y descripción.
paradasCat@bbox

catalunyaPoblacMap@polygons

#Mirar función over para ver a qué municipio pertenece la parada.
#https://gis.stackexchange.com/questions/133625/checking-if-points-fall-within-polygon-shapefile
dat <- data.frame(Longitude = paradasCat@coords[,1], 
                  Latitude = paradasCat@coords[,2],
                  names = paradasCat@data$Nombre_de_)
coordinates(dat) <- ~ Longitude + Latitude
proj4string(dat) <- proj4string(catalunyaPoblacMap)

#Comprobemos que la parada 1 pertenece a Sant Cugat del Vallès.
#Coordenadas de la parada: 

municipioDeCadaParada <- sp::over(dat, catalunyaPoblacMap)
municipioDeCadaParada$NAME_4
#> sp::over(dat, catalunyaPoblacMap)
#GID_0 NAME_0   GID_1   NAME_1     GID_2    NAME_2        GID_3    NAME_3           GID_4
#coords.x1   ESP  Spain ESP.6_1 Cataluña ESP.6.1_1 Barcelona ESP.6.1.10_1 n.a. (36) ESP.6.1.10.15_1
#NAME_4             VARNAME_4       TYPE_4    ENGTYPE_4 CC_4   X COD_INE Poblacion
#coords.x1 Sant Cugat del Vallès Sant Cugat del Vallès Municipality Municipality <NA> 208    8205     92977
nrow(municipioDeCadaParada)
nrow(paradasCat@data)
head(municipioDeCadaParada)

paradasCat@data$Municipio <- municipioDeCadaParada$NAME_4
paradasCat@data$Poblacion <- municipioDeCadaParada$Poblacion
paradasCat@data$COD_INE <- municipioDeCadaParada$COD_INE

head(paradasCat@data)

#A esto queda añadirle el gasto por hogar y ya podemos pasárselo al leaflet para la leyenda.