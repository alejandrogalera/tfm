options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")


library(sp)       #Datos espaciales
library(rgdal)    #Lectura de cartografías
library(rgeos)    #Lectura de cartografías
library(maptools) #Lectura de cartografías
library(readxl)   #Lectura de ficheros Excel
library(tmap)     #Representación de funciones

# dir() para encontrar el nombre del directorio donde están guardados los
# ficheros shape con las cartografías
dir("data/ign/Carto_BCN500")
# Read in shapefile with readOGR(): neighborhoods
#Utilizaremos el mapa Carto_BCN500
#Intento 1 de cálculo de población
#Crea un Large SpatialPolygonsDataFrame: tiene tantas filas como polígonos: 17 CCAA + 2 ciudades autónomas.
dir("data/ign/Carto_BCN500")
poblacion<-readOGR("data/ign/Carto_BCN500", "BCN500_0501P_POBLACION")
poblacion$COD_INE[80]
poblacion$ETIQUETA[80]

#Necesitamos filtrar los municipios por Comunidad Autónoma. Para ello hacemos uso del código INE, ya que 
#los campos de poblacion@data no proporcionan directamente esta información.
#En cambio, sí nos proporciona dicha información la relación oficial de municipios, provincias y comunidades 
#autónomas recogidas en el excel del INE: https://www.ine.es/daco/daco42/codmun/codmun20/20codmun.xlsx

download.file("https://www.ine.es/daco/daco42/codmun/codmun20/20codmun.xlsx", "data/ine/relac_munic_codINE.xlsx")
#Con la inspección de dicho fichero y la información del INE, tenemos que el código INE del Instituto Geográfico
#Nacional, formado por 11 dígitos, se puede identificar unívocamente sólo con los 5 primeros, de los cuales, 
#los dos más significativos se corresponden con el código provincial y los tres siguientes el código de municipio.
listaMunicipios <- read_excel("data/ine/relac_munic_codINE.xlsx", skip = 1)
#La función de tidyverse read_excel lee un excel de disco (por eso hay que hacer el paso previo de la descarga) y 
#acto seguido se almacena en un dataframe.

#Por tanto, separar poblacion@data$COD_INE en los dos primeros por un lado y los tres siguientes por otro, 
#creando sendas variables en @data, nos permitirá realizar operaciones de filtrado por comunidad autónoma y
#provincia.
poblacion@data$COD_PROVINCIA <- substr(poblacion@data$COD_INE, 1, 2)
poblacion@data$COD_MUNICIPIO <- substr(poblacion@data$COD_INE, 3, 5)

#Vamos a mergear la lista de municipios del Excel del INE con la lista de municipios del dataset del IGN.
#Preservaremos para el join el dataset con mayor número de elementos; en este caso, el del IGN poblacion@data
#Ponemos a la variable leída del Excel el mismo nombre que la variable que contiene el nombre del municipio 
#en población@data para hacer join.
listaMunicipios$ETIQUETA <- listaMunicipios$NOMBRE
merge1 <- merge(poblacion@data, 
                listaMunicipios, by = "ETIQUETA", 
                all.x=TRUE, all.y=FALSE, no.dups = TRUE, sort = FALSE)
unique(poblacion@data$ETIQUETA)
head(m)
nrow(m)
length(listaMunicipios$ETIQUETA)

#Hacemos uso del join de la libreria plyr tipo right sobre listaMunicipios
merge2 <- plyr::join(poblacion@data, listaMunicipios, type="left")
nrow(merge2)

sum(is.na(poblacion@data$POB_ENT_SI))
#Hay demasiados missings (1746). Trataremos de buscar la población del INE.


#Otros posibles merge se realizan con las funciones merge o join
catalunyaMunicMap@data$ETIQUETA <- catalunyaMunicMap@data$NAME_4
merge3 <- merge(catalunyaMunicMap@data, poblacion@data, all.x=TRUE, by="ETIQUETA")
merge4 <- plyr::join(poblacion@data, catalunyaMunicMap@data, type="left")
length(merge4$ETIQUETA)
#Aquí se realiza un join a izquierdas y conseguimos 10000 registros, lo cual no es lo deseado, 
#puesto que partíamos de un número menor. Eso nos da una idea de que el join no está haciendo 
#match entre todas las etiquetas.

#A continuación, descargaremos los datos del censo del INE en lugar de utilizar como hasta ahora
#los del IGN (Instituto Geográfico Nacional).
#De aquí en adelante no usaremos la función poblacion@data

#---------------------




#Pasamos a leer un rds para los cálculos por municipio (nivel 4: ESP_4)
download.file("https://biogeo.ucdavis.edu/data/gadm3.6/Rsp/gadm36_ESP_4_sp.rds", 
              "data/gadm/gadm36_ESP_4_sp.rds")
dir("data/gadm")
ESP <- readRDS("data/gadm/gadm36_ESP_4_sp.rds")
#Vemos que NAME_1 contiene las Comunidades Autónomas
unique(ESP$NAME_1)
catalunyaMunicMap <- ESP[ESP$NAME_1=="Cataluña",]
spplot(catalunyaMunicMap, "NAME_4", title ="GADM WGS84 Municipios Cat.")
catalunyaMunicMap@proj4string
sum(is.na(catalunyaMunicMap@data$NAME_4))



save(catalunyaMunicMap, file="data/r/catalunyaMunicMap.RData")
