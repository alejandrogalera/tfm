#Estudio del gasto en transporte por persona y unidad familiar.
#https://ine.es/jaxiT3/Tabla.htm?t=10668&L=1

options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")


library(sp)       #Datos espaciales
library(rgdal)    #Lectura de cartografías
library(rgeos)    #Lectura de cartografías
library(maptools) #Lectura de cartografías
library(readxl)   #Lectura de ficheros Excel
library(tmap)     #Representación de funciones
library(stringr)  #Para str_split_fixed

#Load backups
load("data/r/paradasCat.RData")
load("data/r/numParadasPorLinea.RData")
load("data/r/catalunyaPoblacMap.RData")
load("data/r/paradasLineasNoDup.RData")
catalunyaMap <- rgdal::readOGR("data/arcgis/new", "Prov_Cat_Map_ESR89", 
                driver = "ESRI Shapefile", encoding = "UTF-8")
carrAutoviaCat <- rgdal::readOGR("data/ign/new", "carrAutoviaCat", 
                driver = "ESRI Shapefile", encoding = "UTF-8")
carrAutopistaCat <- rgdal::readOGR("data/ign/new", "carrAutopistaCat", 
                driver = "ESRI Shapefile", encoding = "UTF-8")
carrNacCat <- rgdal::readOGR("data/ign/new", "carrNacCat", 
                driver = "ESRI Shapefile", encoding = "UTF-8")
carrAutonCat <- rgdal::readOGR("data/ign/new", "carrAutonCat", 
                driver = "ESRI Shapefile", encoding = "UTF-8")

#Leemos el fichero csv con el gasto en transporte por familia.
gastoTransporteHousehold <- read.csv("data/ine/gasto_transporte/gasto_transporte_household_10668bsc.csv",
                                     sep = ";")
head(gastoTransporteHousehold)

#Por simplicidad no haremos la serie temporal, sino que adquirimos los datos más recientes (2015) para realizar
#una primera aproximación.
#No tiene mucho sentido aumentar la precisión con una estimación 6 años más tarde de la última fecha de los datos
#del INE ya que la granularidad que ofrece es de muchos menos grupos de la que se ha usado para el estudio
#anterior de población.
gastoTransporteHousehold2015 <- gastoTransporteHousehold[gastoTransporteHousehold$Period==2015,]

#Dividimos el gasto en los tres grupos.
#Creamos una función, ya que lo invocaremos tres veces para este estudio pero puede ser extensible a 
#otros grupos de gasto a analizar.
getExpenditureVar <- function(gasto, expenditure_group)
{
  aux <- gasto
  colnames(aux) <- c("Poblacion", "Grupo_gasto", "Concepto", "Periodo", "Total")
  #Se elimina información redundante.
  aux <- aux[,-c(3,4)]
  aux <- aux[aux$Grupo_gasto==expenditure_group,]
  
  #Hay que transformar factor en double para posteriormente poder realizar operaciones aritméticas.
  #https://stackoverflow.com/questions/3418128/how-to-convert-a-factor-to-integer-numeric-without-loss-of-information
  #Sin embargo, y esto no viene en StackOverflow, es importante eliminar los caracteres ',' ya que en 
  #la transformación a double da error y no lo interpreta como el indicador de millares.
  aux$Total <- as.numeric(
    gsub(",", "", 
         as.character(aux$Total)
         )
    )
  return(aux)
}

gasto1_vehiculos<- getExpenditureVar(gastoTransporteHousehold2015, 
                                     "071 Purchase of vehicles")
gasto2_uso_vehiculo <- getExpenditureVar(gastoTransporteHousehold2015, 
                                         "072 Use of personal vehicles")
gasto3_tra_pub <- getExpenditureVar(gastoTransporteHousehold2015, 
                                    "073 Transport service")

#Inicializamos a cero las tres variables que se rellenarán con la información del estudio de gastos.
fullData <- paradasLineasNoDup
fullData$Gasto_vehiculo     <- rep(0, nrow(paradasLineasNoDup))
fullData$Gasto_uso_veh_pers <- rep(0, nrow(paradasLineasNoDup))
fullData$Gasto_tra_pub      <- rep(0, nrow(paradasLineasNoDup))
fullData$Gasto_total        <- rep(0, nrow(paradasLineasNoDup))


fullData <- dplyr::left_join(fullData, pobCATdf, by=c("Municipio"="Municipio"))
colnames(fullData)
head(fullData[,c(2,8,9,10,11,12,15)])

#Ahora se rellenan las columnas Gasto_vehiculo, Gasto_uso_veh_pers, Gasto_tra_pub con los datos de 
#gasto1_vehiculos, gasto2_uso_vehiculo y gasto3_tra_pub
fullData$Gasto_vehiculo[fullData$Poblacion>=100000] <- 
  gasto1_vehiculos$Total[gasto1_vehiculos$Poblacion=="100,000 or more inhabitants"]
fullData$Gasto_vehiculo[fullData$Poblacion<100000] <- 
  gasto1_vehiculos$Total[gasto1_vehiculos$Poblacion=="From 50,000 to 100,000 inhabitants"]
fullData$Gasto_vehiculo[fullData$Poblacion<50000] <- 
  gasto1_vehiculos$Total[gasto1_vehiculos$Poblacion=="From 20,000 to 50,000 inhabitants"]
fullData$Gasto_vehiculo[fullData$Poblacion<20000] <- 
  gasto1_vehiculos$Total[gasto1_vehiculos$Poblacion=="From 10,000 to 20,000 inhabitants"]
fullData$Gasto_vehiculo[fullData$Poblacion<10000] <- 
  gasto1_vehiculos$Total[gasto1_vehiculos$Poblacion=="Less than 10,000 inhabitants"]

fullData$Gasto_uso_veh_pers[fullData$Poblacion>=100000] <- 
  gasto2_uso_vehiculo$Total[gasto2_uso_vehiculo$Poblacion=="100,000 or more inhabitants"]
fullData$Gasto_uso_veh_pers[fullData$Poblacion<100000] <- 
  gasto2_uso_vehiculo$Total[gasto2_uso_vehiculo$Poblacion=="From 50,000 to 100,000 inhabitants"]
fullData$Gasto_uso_veh_pers[fullData$Poblacion<50000] <- 
  gasto2_uso_vehiculo$Total[gasto2_uso_vehiculo$Poblacion=="From 20,000 to 50,000 inhabitants"]
fullData$Gasto_uso_veh_pers[fullData$Poblacion<20000] <- 
  gasto2_uso_vehiculo$Total[gasto2_uso_vehiculo$Poblacion=="From 10,000 to 20,000 inhabitants"]
fullData$Gasto_uso_veh_pers[fullData$Poblacion<10000] <- 
  gasto2_uso_vehiculo$Total[gasto2_uso_vehiculo$Poblacion=="Less than 10,000 inhabitants"]

fullData$Gasto_tra_pub[fullData$Poblacion>=100000] <- 
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="100,000 or more inhabitants"]
fullData$Gasto_tra_pub[fullData$Poblacion<100000] <- 
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="From 50,000 to 100,000 inhabitants"]
fullData$Gasto_tra_pub[fullData$Poblacion<50000] <- 
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="From 20,000 to 50,000 inhabitants"]
fullData$Gasto_tra_pub[fullData$Poblacion<20000] <- 
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="From 10,000 to 20,000 inhabitants"]
fullData$Gasto_tra_pub[fullData$Poblacion<10000] <- 
  gasto3_tra_pub$Total[gasto3_tra_pub$Poblacion=="Less than 10,000 inhabitants"]

#Por último, sumamos el total en la columna Gasto_total de entre estos tres conceptos.
fullData$Gasto_total <- fullData$Gasto_vehiculo + fullData$Gasto_uso_veh_pers + fullData$Gasto_tra_pub

#Veamos cómo ha quedado el dataset.
#Elimino algunas columnas sólo para la representación, para que se vea más claramente lo que se ha calculado
#en estos pasos.
fullData[,c(2,8,9,10,11,12,15)]

save(fullData, file = "data/r/fullData.RData")
