#Serie temporal de la movilidad en Cataluña.
setwd('5.DesplazamientosINE')
dir()
options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")

##########################################
#1. Procesamiento de datos (CSV del INE)

movilidad <- read.csv('36193bsc.csv', header = TRUE)
movilidad[] <- lapply(movilidad, as.character)
colnames(movilidad)

#Vemos que ha parseado de una forma incorrecta el nombre de las columnas, por lo que pasamos 
#a setearlas a mano.

#X.reas.de.movilidad.Tipo.de.dato.Periodo.Total
#Catalu\361a;Porcentaje de poblaci\363n que sale del \341rea;20/6/2020;20   25                                           25
#Catalu\361a;Porcentaje de poblaci\363n que sale del \341rea;19/6/2020;22   44                                           44
#Catalu\361a;Porcentaje de poblaci\363n que sale del \341rea;18/6/2020;21   70                                           70

#Además, se puede eliminar la primera y segunda columna (de las separadas por ";"), 
#que son, respectivamente, Cataluña y el Porcentaje de población que sale del área 
#como tipo de dato
movilidad <- read.csv('36193bsc.csv', header = FALSE, sep = ";")
movilidad <- movilidad[,c(3,4)]
colnames(movilidad) <- c("Fecha", "Porcentaje_movilidad")

summary(movilidad)

#Lo siguiente es eliminar las filas con porcentaje vacío.
movilidad <- movilidad[movilidad$Porcentaje_movilidad!="",]
#No se usa el na.omit(movilidad) ya que la columna es cadena vacía, no NA, como 
#se mostró con el summary(movilidad)
#Eliminamos también la única componente que muestra una mayor discontinuidad, que es la del 18/11/2019.
movilidad <- movilidad[!grepl("2019", movilidad$Fecha),]
movilidad$Porcentaje_movilidad <- as.numeric(gsub(",", ".", movilidad$Porcentaje_movilidad))
movilidad <- na.omit(movilidad)

#El siguiente paso es convertir los formatos de las columnas de carácter a fecha/numérico.
movilidad$Fecha <- as.Date(movilidad$Fecha, format="%d/%m/%Y")
plot(movilidad)
movilidad

#Téngase en cuenta que antes del 30 de marzo sólo se tienen datos de los días pares, por lo que
#de forma simplificada, se puede tomar el inicio de la serie el día 30 de marzo, eliminando las 
#anteriores.
#En un estudio más exhaustivo habría que generar NA y hacer uso de na.interp, pero dado que es un 
#estudio a grosso modo para calcular la tendencia, no es necesario y se puede simplificar.
movilidad2 <- movilidad[!movilidad$Fecha<as.Date("2020-03-30"),]
movilidad2

#Por último, es muy importante que el dataset tenga las filas ordenadas en sentido de creciente, 
#es decir, de más antigua a más reciente.
#Como el dataframe está invertido y aparece con el primer valor más reciente que el último, 
#podemos ejecutar:
movilidad3<- movilidad2[seq(dim(movilidad2)[1],1),]
movilidad3
#Otra forma más elegante de realizar esta ordenación es con la función order.
movilidad4<- movilidad2[order(as.Date(movilidad2$Fecha, format="%d/%m/%Y")),]
movilidad4

#2. Representación gráfica
#Representamos gráficamente la serie temporal.
library(ggplot2)
library(ggfortify)
#Necesitamos conocer el día del año.
doy <- as.numeric(strftime(min(movilidad4$Fecha), format = "%j"))
doy
v_mov <- ts(movilidad4[,-1], start=c(2020,doy), frequency = 365)
autoplot(v_mov)

#Para representar de una forma más amigable la fecha en el eje x, es interesante
#hacer uso de la librería zoo. De este modo evitamos representar el día del año, 
#entendiéndose como tal la posición del día en los 365.
library(zoo)
dt=seq(from=as.Date("2020/03/30"), by="day", length.out=nrow(movilidad4))
v_movZ = zoo(x=movilidad4[,2], order.by = dt)
autoplot(v_movZ)+
  ggtitle("Tasa de movilidad en Cataluña (%personas fuera de su área)")+
  xlab("dia")+ylab("%personas")

#Se observa a simple vista con el autoplot una tendencia estacional creciente, 
#luego no es necesario realizar una descomposición estacional para concluir la tendencia
#creciente. Si aun así se desease predecir la tasa de movilidad de las personas 
#a partir de la fecha máxima, el 20 de Junio de 2020, habría que usar la función decompose:
autoplot(decompose(v_mov, type=c("multiplicative")))
#En este caso, además la serie es muy escasa en número de datos, por lo que podríamos 
#obtener el siguiente error al tratar de ejecutar el decompose:
#Error in decompose(v_mov, type = c("multiplicative")) : 
#  time series has no or less than 2 periods
