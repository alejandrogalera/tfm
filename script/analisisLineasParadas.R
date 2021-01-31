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
paradasCat<-readOGR("data/opendata_esri/paradas","PARADAS_DEFINITIVO")

load("data/r/catalunyaMunicMap.RData")

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
  tm_dots(title = "paradas", col = 'blue', size = 0.01)

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



Mirar función over para ver a qué municipio pertenece la parada.
