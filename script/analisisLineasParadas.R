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
#A continuación se ordenarán para estudiar si nuestra empresa debería centrarse en los operadores que disponen
#de más lineas, usan más paradas y por tanto presumiblemente tendrán una flota mayor, o bien debería contemplar 
#las empresas minoritarias (o long tail) para ofrecer un servicio conjunto que optimice sus beneficios, como 
#por ejemplo no compitiendo entre sí por zonas poco pobladas.

######
#Vamos a calcular el número de paradas que tiene cada operador y lo ordenaremos.
#Con esto se podrá ofrecer un servicio de análisis de la competencia centralizado.
#https://dplyr.tidyverse.org/reference/count.html
operadores <- paradasCat@data %>% dplyr::count(Operador)
nrow(operadores)
# [1] 120
#Vemos que tenemos paradas de 120 operadores entre los que destacan como mayoritarios:
operadores[order(operadores$n, decreasing = TRUE),]


#Veamos el número de paradas por línea.
paradasLineas <- paradasCat@data[,c(1,5,7)]
paradasLineas <- paradasLineas %>%
  dplyr::group_by(Nombre_d_1,Operador) %>%
  dplyr::count()

nrow(lineas)
summary(as.vector(lineas$n))
var(as.vector(lineas$n))
#Tenemos una distribución de paradas por línea muy asimétrica, con valores extremos muy alejados de la media,
#fruto de lo cual está desplazada la media de la mediana.
#Otra forma de ver esta asimetría es con el estadístico de la kurtosis, que se obtiene positiva.
#Hacemos uso de la función skewness de la librería moments.
#https://www.geeksforgeeks.org/skewness-and-kurtosis-in-r-programming/
moments::skewness(as.vector(lineas$n))
#Parece que tenemos outliers. Resulta llamativo que haya una línea con 1447 paradas.

head(paradasLineas[order(paradasLineas$n, decreasing = TRUE),])

######
## Eliminación de duplicados.
#Comenzamos eliminando los FID que provocan los duplicados..
#Una forma de realizarlo es hacer directamente paradasLineas <- unique(paradasLineas), 
#pero perderíamos la información de FID.
#Lo que haremos es agrupar por el mínimo de FID.
paradasLineas <- paradasCat@data
paradasLineas <- paradasLineas %>%
  na.omit() %>%
  dplyr::group_by(Nombre_d_1, COORD_X, COORD_Y,
                  Municipio) %>%
  mutate(FID = min(FID, na.rm = TRUE)) %>%
  arrange(FID, Nombre_d_1, COORD_X, COORD_Y,
          Municipio)
paradasLineasNoDup <- unique(paradasLineas)

#Hemos pasado de 49438 registros a 19260.
summary(paradasLineasNoDup)

numParadasPorLinea <- paradasLineasNoDup[,c(1,5)]
numParadasPorLinea <- numParadasPorLinea %>%
  dplyr::group_by(Nombre_d_1) %>%
  dplyr::count()

head(numParadasPorLinea[order(numParadasPorLinea$n, decreasing = TRUE),])

summary(numParadasPorLinea$n)

moments::skewness(as.vector(numParadasPorLinea$n))


####################
## Cálculo de municipio correspondiente a la parada.
#En primer lugar, contamos los NA en el nombre de la parada y descripción.
paradasCat@bbox
catalunyaPoblacMap@polygons

#https://gis.stackexchange.com/questions/133625/checking-if-points-fall-within-polygon-shapefile
dat <- data.frame(Longitude = paradasCat@coords[,1], 
                  Latitude = paradasCat@coords[,2],
                  names = paradasCat@data$Nombre_de_)
coordinates(dat) <- ~ Longitude + Latitude
proj4string(dat) <- proj4string(catalunyaPoblacMap)

#Comprobemos que la parada 1 pertenece a Sant Cugat del Vallès.
#Coordenadas de la parada: 

municipioDeCadaParada <- sp::over(dat, catalunyaPoblacMap)
head(municipioDeCadaParada$NAME_4)
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
paradasCat$Municipio <- municipioDeCadaParada$NAME_4

save(paradasCat, file = "data/r/paradasCat.RData")
save(numParadasPorLinea, file = "data/r/numParadasPorLinea.RData")
save(paradasLineasNoDup, file = "data/r/paradasLineasNoDup.RData")