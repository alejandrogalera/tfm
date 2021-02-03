options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")


library(sp)       #Datos espaciales
library(rgdal)    #Lectura de cartografías
library(rgeos)    #Lectura de cartografías
library(maptools) #Lectura de cartografías
library(readxl)   #Lectura de ficheros Excel
library(tmap)     #Representación de funciones
library(stringr)  #Para str_split_fixed

##Estudio Población INE.
#######################
#Usando la librería sql de R con los archivos de datos del INE:
#Cifras oficiales de población resultantes de la revisión del Padrón municipal a 1 de enero
urlINE_BCN <- "https://www.ine.es/jaxiT3/files/t/es/xlsx/2861.xlsx?nocab=1"
urlINE_GIR <- "https://www.ine.es/jaxiT3/files/t/es/xlsx/2870.xlsx?nocab=1"
urlINE_LLE <- "https://www.ine.es/jaxiT3/files/t/es/xlsx/2878.xlsx?nocab=1"
urlINE_TAR <- "https://www.ine.es/jaxiT3/files/t/es/xlsx/2900.xlsx?nocab=1"

#Función que devuelve, a partir de las URL del INE de los Excel con la población por municipios, un dataframe
#con la siguiente estructura:
# COD_INE | Municipio | Poblacion
#---------+-----------+-----------
# XXXXX   | Nombre    | 2153...
getPoblacionDataFrame <- function(ine_url) 
{
  download.file(ine_url, "data/ine/provisional.xlsx")
  
  pob_xls <- read_excel("data/ine/provisional.xlsx")
  #pob_df
  #Detalle municip… NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
  #2 NA               NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
  #3 Barcelona: Pobl… NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
  #4 Unidades:   Per… NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
  #5 NA               NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
  #6 NA               Total NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA    NA   
  #7 NA               2020  2019  2018  2017  2016  2015  2014  2013  2012  2011  2010  2009  2008  2007  2006  2005 
  #8 08 Barcelona     5743… 5664… 5609… 5576… 5542… 5523… 5523… 5540… 5552… 5529… 5511… 5487… 5416… 5332… 5309… 5226…
  #Hay que hacer skip de 7 líneas de encabezado y la octaba del total provincial, y seleccionar la columna del 
  #año más reciente (primera columna: 2020).
  pob_xls <- read_excel("data/ine/provisional.xlsx", skip = 8)
  pob_df <- as.data.frame(pob_xls)
  #Nombramos las columnas
  colnames(pob_df) <- c("COD_INE_MUNICIPIO", "Poblacion")
  #Eliminamos las estadísticas del resto de años.
  pob_df <- pob_df[, c(1,2)]
  
  #Téngase en cuenta que obtener los datos de forma automatizada de este dataset no es trivial, ya que podría contener
  #al final líneas que no fuesen del tipo "XXXXX Nombre del municipio", siendo XXXXX caracteres numéricos, deberían
  #ser descartadas para poder hacer el split de la columna en "XXXXX" por un lado y "Nombre del municipio" por otro
  #sin problemas derivados del formato.
  #grepl identifica el formato mencionado. A diferencia de grep, que devuelve los valores en sí, 
  grepl("^[0-9]+ .*", pob_df$COD_INE_MUNICIPIO)
  #Es más directo hacer un na.omit en este caso ya que la columna de población puede contener NA al final del 
  #documento
  pob_df <- na.omit(pob_df)
  
  #Ahora hay que splitear la variable pobBCNdf$COD_INE_MUNICIPIO en CON_INE y Municipio.
  splitted <- str_split_fixed(pob_df$COD_INE_MUNICIPIO, " ", 2)
  pob_df$COD_INE <- splitted[,1]
  pob_df$Municipio <- splitted[,2]
  #Eliminamos COD_INE_MUNICIPIO una vez separado el dataset.
  pob_df$COD_INE_MUNICIPIO <- NULL
  #Reordenamos las columnas antes de guardar el dataframe.
  pob_df <- pob_df[, c(2,3,1)]
  
  #Borrado del fichero xls descargado.
  file.remove("data/ine/provisional.xlsx")
  
  return(pob_df)
}  

#Obtenemos los dataframe de cada provincia de Cataluña
pobBCNdf <- getPoblacionDataFrame(urlINE_BCN)
pobGIRdf <- getPoblacionDataFrame(urlINE_GIR)
pobLLEdf <- getPoblacionDataFrame(urlINE_LLE)
pobTARdf <- getPoblacionDataFrame(urlINE_TAR)

#Por último, concatenamos los dataframes para obtener la población de Cataluña y lo guardamos en CSV.
pobCATdf <- rbind(pobBCNdf, pobGIRdf, pobLLEdf, pobTARdf)

#Checkpoint de backup
#Para asegurarnos de que se guarda como UTF-8 asignamos el fichero con codificación UTF-8 a un 
#descriptor de fichero.
#https://stackoverflow.com/questions/3792846/how-to-export-a-csv-in-utf-8-format
con <- file("data/ine/poblacionCAT.csv", encoding = "UTF-8")
write.csv(pobCATdf, con)
pobCATdf <- read.csv("data/ine/poblacionCAT.csv", encoding = "UTF-8")

#Ahora queda combinar el mapa de límites municipales catalunyaPoblacMap con el CSV generado, haciendo join 
#por el nombre de la localidad: NAME_4 para catalunyaPoblacMap, Municipio para pobCATdf
nrow(pobCATdf)

dir("data/r")
load("data/r/catalunyaMunicMap.RData")
catalunyaPoblacMap <- catalunyaMunicMap
catalunyaPoblacMap@data<-dplyr::left_join(catalunyaMunicMap@data,pobCATdf, by=c("NAME_4"="Municipio"))

#Representamos el mapa con tm_shape de tmap
tm_shape(catalunyaPoblacMap) +
  tm_borders() +
  tm_fill(col = "Poblacion", n=10)+
  tm_layout(title= 'Revision del Padron Municipal.\n     Fuente: INE', 
            legend.just = "right",
            title.position = c('right', 'top'))


#Gestión de missings
#Dado que los datasets de los que partíamos no tenían un código asociado para todos los municipios y hemos 
#tenido que hacer el join por el nombre del pueblo.
#Esto presenta una serie de posibles problemas como tildes, espacios, comas, poner artículos antes o después, 
#idioma del pueblo (Gerona/Girona), etc. Todo esto puede hacer que el mismo pueblo no haga match al combinar
#ambos datasets y aparezcan missings.
#Contamos el número de missings en las variables añadidas al dataset que no tienen población asociada al conjunto
#de puntos.
sum(is.na(catalunyaPoblacMap$Poblacion))
sum(is.na(catalunyaPoblacMap$COD_INE))
#Salen 142

#Veamos a qué pueblos se refieren esos missings.
catalunyaPoblacMap$NAME_4[is.na(catalunyaPoblacMap$COD_INE)]
#Mediante inspección visual se comprueba que muchos de los pueblos que aparecen como missing se deben a que 
#en el dataset del mapa de GADM aparecen como "L'Ametlla del Vallès" mientras que en el INE viene como 
#"Ametlla del Vallès, L'". 
#Esto sucede en muchos otros pueblos como "Cabanyes, Les" para el INE que aparecen en el dataset del mapa como
#"Les Cabanyes".
#Para reducir el número de NA, splitearemos la columna nombre en el CSV del INE ordenando el nombre del municipio
#sin la coma. Tras esto, repetiremos el join y analizaremos cuántos missings hemos recuperado de esos 142.
sum(grepl(", ", pobCATdf$Municipio))

#Aquí hay que tener cuidado porque conviene expresar explícitamente el paquete dplyr para evitar problemas
#con otras funciones de otras variables que sea homónimas.
municToSplitComma <- dplyr::filter(pobCATdf, grepl(", ", pobCATdf$Municipio))

#Calculamos el separador, que será espacio si el determinante no finaliza con apóstrofo,
#mientras que será cadena vacía en caso de que haya que usar "L'" como segundo valor 
#de la lista spliteada.
getSeparator <- function(s) { return(grep(".*[^']$", s))}

#Definimos la función que ordena los nombres de municipios con coma, aprovechando la definición del 
#la función getSeparator
orderNameWithComma <- function(s)
{
  options(encoding = "UTF-8")
  Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")
  
  #Es recomendable usar tryCatch en las primeras definiciones de una función para 
  #capturar las excepciones de tipo warning y error.
  out <- tryCatch(
    {
      #Es muy importante setear useBytes=TRUE para hacer el match byte a byte y 
      #evitar conversiones indeseadas de codificación si se hace carácter a carácter
      splitted <- strsplit(as.character(s), ", ", useBytes = TRUE)
      separator <- stringr::str_c("",strrep(" ", getSeparator(splitted[[1]][2])))
      #Es necesario concatenar "" a lo que devuelve getSeparator ya que 
      #character(0) y "" se comportan con el mismo typeof y class pero la primera
      #forma no se admite como separator en funciones como paste. Por ese motivo
      #se necesita partir de una cadena vacía. 
      #Aunque character(0) y "" tienen mismo class y type, no devuelve true 
      #la función identical(character(0), "")
      res <- stringr::str_c(splitted[[1]][2], splitted[[1]][1], sep = separator)
      cat("res:[",res,"]\n",sep="")
      return(res)
    },
    error = function(cond) {
      message(cat(cond, "[", s, "]", sep = ""))
      return(error)
    }
  )
  return(out)
}

sapply(municToSplitComma$Municipio, 
       orderNameWithComma, 
       USE.NAMES=FALSE, 
       simplify = TRUE)

#En lugar de añadir estos elementos ordenados al resto del dataframe, es muy recomendable hacer que la función
#sea inocua para los nombres de municipio sin coma y así aplicarla a todo el dataframe.
#Redefinimos por tanto la función orderNameWithComma añadiendo que devuelva el parámetro de entrada si no 
#encuentra coma en "Municipio", es decir, si la longitud del elemento [[1]] de la lista (resultado del split)
#es mayor que 1 (caracter coma encontrado).
orderNameWithComma <- function(str)
{
  options(encoding = "UTF-8")
  Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")
  
  s <- as.character(str)
  splitted <- strsplit(s, ", ", useBytes = TRUE)
  if (length(splitted[[1]])>1)
  {
    separator <- stringr::str_c("",strrep(" ", getSeparator(splitted[[1]][2])))
    s <- stringr::str_c(splitted[[1]][2], splitted[[1]][1], sep = separator)
  }
  return(s)
}

#La lista de poblaciones ordenadas queda como sigue:
pobCATdf_ordered <- pobCATdf
pobCATdf_ordered$Municipio <- sapply(pobCATdf$Municipio, 
                                     orderNameWithComma, 
                                     USE.NAMES=FALSE, 
                                     simplify = TRUE)

#Si se pusiera USE.NAMES = TRUE, el vector/lista resultado tendría como nombre el valor anterior
#a aplicar el sapply.
#Además, queremos obtener un array, por lo que seleccionamos simplify = TRUE. De lo contrario sería una 
#lista de n elementos siendo vectores de tamaño 1. Seleccionamos, por tanto, los parámetros para simplificar su
#uso: USE.NAMES=FALSE y simplify=TRUE.


#Antes de pasar a hacer el nuevo Join vamos a eliminar nombres duplicados, como L'Espluga de Francoli que separa
#con un pipe | dos formas de nombrar un mismo pueblo.
catalunyaMunicMap$NAME_4[grepl("\\|", catalunyaMunicMap$NAME_4)]
#Como solo hay un valor lo cambiamos a mano.
catalunyaMunicMap$NAME_4[grepl("\\|", catalunyaMunicMap$NAME_4)] <- "L'Espluga de Francolí"


#Otro ajuste es eliminar las VARNAME_4 NA
sum(is.na(catalunyaMunicMap$NAME_4))
sum(is.na(catalunyaMunicMap$VARNAME_4))
catalunyaMunicMap$VARNAME_4 <- catalunyaMunicMap$NAME_4

#Procedemos a realizar el Join.
catalunyaPoblacMap@data<-dplyr::left_join(catalunyaMunicMap@data,
                                          pobCATdf_ordered, 
                                          by=c("NAME_4"="Municipio"))
sum(is.na(catalunyaPoblacMap$Poblacion))
#Hemos conseguido reducir considerablemente el número de NA a 15.
catalunyaPoblacMap$NAME_4[is.na(catalunyaPoblacMap$Poblacion)]

#[1] "Cabrera d'Igualada"                                            
#[2] "Santa Maria de Corcó"                                          
#[3] "El Papio"                                                      
#[4] "Boadella d'Empordà"                                            
#[5] "Saus"                                                          
#[6] "Brunyola"                                                      
#[7] "Calonge"                                                       
#[8] "Cruïlles, Monells i Sant Sadurní de l'Heura"                   
#[9] "La Bisbal d'Emporda"                                           
#[10] "La Mancomunitat dels Quatre Pobles (Alt Àneu y Esterri d'Àneu)"
#[11] "El Alamús"                                                     
#[12] "El Alamús"                                                     
#[13] "Passanant"                                                     
#[14] "Roda de Barà"                                                  
#[15] "Vimbodí" 

#El nombre Cabrera d'Igualada es incorrecto, ya que en castellano es Cabrera de Igualada y en catalán
#Cabrera d'Anoia
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Cabrera d'Igualada"]<-"Cabrera d'Anoia"
#https://www.ine.es/intercensal/intercensal.do?search=3&codigoProvincia=08&codigoMunicipio=517&btnBuscarCod=Consultar+selecci%F3n
#Santa María de Corcó se denomina oficialmente L'Esquirol según el INE
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Santa Maria de Corcó"]<-"L'Esquirol"
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="El Papio"]<-"El Papiol"
#Según el IDESCAT, Calonge es Calonge i Sant Antoni.
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Calonge"]<-"Calonge i Sant Antoni"

#Seguimos asignando los nombres oficiales según el INE y la agrupación del censo.
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Boadella d'Empordà"]<-"Boadella i les Escaules"
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Brunyola"]<-"Brunyola i Sant Martí Sapresa"
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Passanant"]<-"Passanant i Belltall"
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Vimbodí"]<-"Vimbodí i Poblet"

#En el caso de "Cruïlles, Monells i Sant Sadurní de l'Heura", tenemos un pueblo al que se ha aplicado 
#de forma indeseada el sapply para eliminar la coma. Debemos restaurarlo en el pobCATdf_ordered
pobCATdf_ordered$Municipio[startsWith(pobCATdf_ordered$Municipio, "Monells")] <- "Cruïlles, Monells i Sant Sadurní de l'Heura"
#Algo análogo ocurre con la agrupación "Saus, Camallera i Llampaies".
pobCATdf_ordered$Municipio[startsWith(pobCATdf_ordered$Municipio, "Camallera")] <- "Saus, Camallera i Llampaies"
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Saus"]<-"Saus, Camallera i Llampaies"

#Falta una tilde en "La Bisbal d'Emporda"
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="La Bisbal d'Emporda"]<-"La Bisbal d'Empordà"
#En el pueblo El Alamús, según el nombre oficial una s, unificando Alamús.
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="El Alamús"]<-"Els Alamús"
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="Roda de Barà"]<-"Roda de Berà"

#Estos valores aquí modificados se podían haber despreciado como NA. No obstante, con el fin de tener un 
#dataset de partida correcto que aúne los nombres oficiales del INE con la división del mapa GADM e IGN, 
#modificaremos manualmente los pocos que faltan.
#"La Mancomunitat dels Quatre Pobles (Alt Àneu y Esterri d'Àneu)" es un único polígono que debe sumar las 
#poblaciones de Alt Àneu (414) y Esterri d'Àneu (804). 
#Por simplicidad asignaremos el nombre de la más significativa.
catalunyaMunicMap$NAME_4[catalunyaMunicMap$NAME_4=="La Mancomunitat dels Quatre Pobles (Alt Àneu y Esterri d'Àneu)"]<-"Esterri d'Àneu"

catalunyaMunicMap$VARNAME_4 <- catalunyaMunicMap$NAME_4
#Procedemos a realizar el Join.
catalunyaPoblacMap@data<-dplyr::left_join(catalunyaMunicMap@data,
                                          pobCATdf_ordered, 
                                          by=c("NAME_4"="Municipio"))
sum(is.na(catalunyaPoblacMap$Poblacion))


#-------------------------------
#Ya que tenemos el dataset correctamente, realizamos un checkpoint de backup.
con <- file("data/ine/poblacionCAT_orderedName.csv", encoding = "UTF-8")
write.csv(pobCATdf_ordered, con)
pobCATdf_ordered <- read.csv("data/ine/poblacionCAT_orderedName.csv", encoding = "UTF-8")
save(catalunyaMunicMap, file = "data/r/catalunyaMunicMap.RData")
save(catalunyaPoblacMap, file = "data/r/catalunyaPoblacMap.RData")
load("data/r/catalunyaPoblacMap.RData")
load("data/r/catalunyaMunicMap.RData")
#-------------------------------

#Media ponderada de las poblaciones. 
#Tenemos un valor de densidad de población en Barcelona mucho mayor que en el resto, por lo que para evitar la 
#homogeneidad en el color de la representación debemos reducir la asimetría respecto de la media. 
#Lo primero que podría realizarse es una normalización, es decir, restar a cada elemento la media y dividir por 
#la desviación típica.
#Esto es útil para cálculos estadísticos, pero para una mera representación, es suficiente con reasignar el 
#valor máximo (Barcelona). Se le seteará una población ligeramente mayor que la mayor de todas.
max(catalunyaPoblacMap$Poblacion)
#Otra forma de obtener el máximo es ordenar la lista de forma decreciente y obtener el primer elemento [1]
#Para el siguiente, [2], y así sucesivamente.
#https://stat.ethz.ch/R-manual/R-devel/library/base/html/sort.html
sort(catalunyaPoblacMap$Poblacion, decreasing = TRUE)[c(1:5)]
sort(catalunyaPoblacMap$Poblacion, decreasing = TRUE)[2]
#Asignamos a Barcelona un valor de 300000 para que sea redondo y no produzca el efecto visual de un outlier 
#en el color.
catProvisionalParaGraf<-catalunyaPoblacMap
catProvisionalParaGraf$Poblacion[catalunyaPoblacMap$NAME_4=="Barcelona"]<-300000

#Representamos el mapa con tm_shape de tmap
library(RColorBrewer)
mipaleta = c("orange1", "red", "green3", "blue", "cyan", "magenta", "yellow","gray", "black")

tm_shape(catProvisionalParaGraf) +
  tm_borders() +
  tm_fill(col = "Poblacion", n=100, palette = mipaleta)+
  tm_layout(main.title= 'Revision del Padron Municipal. Fuente: INE', 
            legend.outside = TRUE,
            legend.outside.position = "right",
            legend.hist.size = 2,
            legend.text.size = 2,
            main.title.position = c('left', 'top'))

save(catProvisionalParaGraf, file="data/r/catProvisionalParaGraf.RData")
save(catalunyaPoblacMap, file="data/r/catalunyaPoblacMap.RData")
