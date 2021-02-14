#!/usr/bin/env Rscript
#Script para la ejecución del enrutado.
options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")

#Librerías
library(sp)       #Datos espaciales
library(rgdal)    #Lectura de cartografías
library(rgeos)    #Lectura de cartografías
library(maptools) #Lectura de cartografías
library(readxl)   #Lectura de ficheros Excel
library(tmap)     #Representación de funciones
library(stringr)  #Para str_split_fixed
library(leaflet)  #Mapas web interactivos.
library(htmlwidgets) #Guardar gráficos en html.

library(tmaptools) #Para OSRM
library(osrm)

library(spdep)    #Econometría espacial
library(sphet)    #Modelos de regresión espacial con heterocedasticidad
library(spatialreg) #Regresión espacial
# library(spse) # spse: Spatial Simultaneous Equations and Spatial Sur Model
#install.packages("spse", repos="http://R-Forge.R-project.org")

library(RColorBrewer) 
library(classInt)
library(scales)
library(stargazer) #Tablas de resultados de modelos de regresión


#Cargamos el shape de cartografía con los términos municipales proporcionados por GADM.
load("data/r/catalunyaFull.RData")
#A este dataset de catalunyaFull hay que incorporar el número de paradas en cada municipio.
load("data/r/paradasLineasNoDupMunicipio.RData")

numParadas <- paradasLineasNoDup %>%
        dplyr::group_by(Municipio) %>%
        dplyr::count()
colnames(numParadas) <- c("Municipio", "Num_paradas")

catalunyaFullNumParadas <- catalunyaFull
catalunyaFullNumParadas@data<-dplyr::left_join(catalunyaFull@data,
                                     numParadas, 
                                     by=c("NAME_4"="Municipio"))
#El SpatialPolygonDataFrame ya contiene además de los datos georreferenciados las variables Poblacion,
#Gasto_tra_pub y Num_Paradas.

hist(catalunyaFullNumParadas@data$Gasto_tra_pub)
hist(catalunyaFullNumParadas@data$Num_paradas)
#Vemos que la mayoría de municipios tienen pocas paradas y luego hay otros con una alta concentración.


#Análisis de missings
table(is.na(catalunyaFullNumParadas@data$Gasto_tra_pub))
table(is.na(catalunyaFullNumParadas@data$Num_paradas))
#Los 48 true de Num_paradas nos indica que al hacer el Join no se encontraron paradas en 48 municipios.
#Hay que eliminar estos missing y setearlos a cero.
catalunyaFullNumParadas@data$Num_paradas[is.na(catalunyaFullNumParadas@data$Num_paradas)]<-0
table(is.na(catalunyaFullNumParadas@data$Gasto_tra_pub))
table(is.na(catalunyaFullNumParadas@data$Num_paradas))
#Ya tenemos los 955 sin missings.

#Mapas descriptivos por cuantiles.
xmax<-max(coordinates(catalunyaFullNumParadas)[,1])
xmin<-min(coordinates(catalunyaFullNumParadas)[,1])
ymax<-max(coordinates(catalunyaFullNumParadas)[,2])
ymin<-min(coordinates(catalunyaFullNumParadas)[,2])

#?brewer_pal

#Mapa del número de paradas de bus por cuantiles
ColorBr="Greens" 
varName<-"Num_paradas"
par(mar=c(0,0,0,0))
#Está deprecado el uso de brewer.pal -> brewer_pal(palette = ColorBr)(5)
breaks<-classIntervals(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 
                       9, style="quantile")
color <- findColours(breaks,palette(brewer_pal(palette = ColorBr)(5)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 
                                        digits=0), 5, style="quantile"),
                   palette(brewer_pal(palette = ColorBr)(5)),
                   under="menor que", 
                   over="mayor que", between="-", digits=0,
                   cutlabels=FALSE)

plot(catalunyaFullNumParadas, col = color, lty=1, border=NA, lwd=0.25, 
     add=F,  axes=F, pch=19, 
     xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.70,y = 37.5,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = varName, cex=0.75, box.lty=0, border = 0)

#Mapa del gasto en transporte.
jpeg(file=paste0("media/plotGastoTransporte.jpeg"), height=500, width = 500*1.397,
     bg ="transparent", quality = 100)
ColorBr="PuBuGn"
varName<-"Gasto_tra_pub"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 9, style="quantile")
color <- findColours(breaks,palette(brewer_pal(palette = ColorBr)(5)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 
                                        digits=2), 5, style="quantile"),
                   palette(brewer_pal(palette = ColorBr)(5)), under="menor que", over="mayor que", 
                   between="-", digits=0, cutlabels=FALSE)

#Añado un diferencial para que los quantiles no salgan iguales y se pueda representar.
quantile(catalunyaFullNumParadas$Gasto_tra_pub)
#Si los cuantiles son iguales, la función de leaflet da error "Cut() error - 'breaks' are not unique"
#Se puede realizar lo que propone la comunidad StackOverflow https://stackoverflow.com/questions/16184947/cut-error-breaks-are-not-unique
#o añadir un diferencial para que los cuantiles no coincidan y por tanto el cut no detecte breaks coincidentes.
addDifferential <- function(x) {
        return(x+runif(1, 0.0001, 0.0010))
}

catalunyaFullNumParadas$Gasto_tra_pub <- sapply(catalunyaFullNumParadas$Gasto_tra_pub,addDifferential)
#Ya tenemos cuantiles diferentes.
quantile(catalunyaFullNumParadas$Gasto_tra_pub)

#Volvemos a generar los breaks.
breaks<-classIntervals(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 9, style="quantile")
color <- findColours(breaks,palette(brewer_pal(palette = ColorBr)(5)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 
                                        digits=2), 5, style="quantile"),
                   palette(brewer_pal(palette = ColorBr)(5)), under="menor que", over="mayor que", 
                   between="-", digits=0, cutlabels=FALSE)

#Representación gráfica
plot(catalunyaFullNumParadas, col = color, lty=1, border=NA, lwd=0.25, add=F, axes=F, pch=19,
     xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37, fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = varName, cex=0.6, box.lty=0, border=0)

#Se almacena el Jpeg en ./media.
dev.off()
par(mar=c(5.1, 4.1, 4.1, 2.1))

#Observando estos gráficos se podría decir que los municipios con un mayor número de paradas realizan un mayor gasto
#en transporte público a grosso modo.

#Creamos la matriz de pesos espaciales.
#Método de contiguidad de la Reina
list.queen<-poly2nb(catalunyaFullNumParadas, queen=TRUE)
W<-nb2listw(list.queen, style="W", zero.policy=TRUE)

#Histograma del número de vecinos por contiguidad de la reina.
raster::hist(card(list.queen)) 
summary(card(list.queen))

#Mapa de contigüidades
par(mar=c(0,0,0,0))
plot(catalunyaFullNumParadas, border="grey")
plot(W,coordinates(catalunyaFullNumParadas),add=TRUE)
par(mar=c(5.1, 4.1, 4.1, 2.1))

par(mar=c(0,0,0,0))
plot(catalunyaFullNumParadas, border="grey",xlim=c(-0.5,0.5), ylim=c(37,40))
plot(W,coordinates(catalunyaFullNumParadas), add=TRUE)
par(mar=c(5.1, 4.1, 4.1, 2.1))

#Una vez que tenemos calculada la matriz de pesos obtenemos WM para calcular los retardos espaciales.
WM<-listw2mat(W)
dim(WM)
#Se crea una matriz 955x955 con todos los municipios y calculamos el retardo espacial del gasto en transporte.

catalunyaFullNumParadas@data$Gasto_tra_pub_W<-(WM%*%catalunyaFullNumParadas@data$Gasto_tra_pub)[,1]

#comparamos los parámetros con el retardo espacial.
summary(catalunyaFullNumParadas@data$Gasto_tra_pub)
summary(catalunyaFullNumParadas@data$Gasto_tra_pub_W)

table(is.na(catalunyaFullNumParadas@data$Gasto_tra_pub_W))
#No tiene NA's

par(mar=c(5.1, 4.1, 4.1, 2.1))

hist(catalunyaFullNumParadas@data$Gasto_tra_pub, nclass = 20, col=3, freq = FALSE)
hist(catalunyaFullNumParadas@data$Gasto_tra_pub_W, nclass=20, col=2, freq=FALSE)

plot(density(catalunyaFullNumParadas@data$Gasto_tra_pub_W), col="red", lwd=2, main="")
lines(density(catalunyaFullNumParadas@data$Gasto_tra_pub), col="darkgreen", lwd=2)
legend("topright",col=c("red","darkgreen"),legend = c("Gasto_tra_pub_W","Gasto_tra_pub"), lty=1,lwd=2)



ColorBr="PuBuGn"
varName<-"Gasto_tra_pub_W"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 9, style="quantile")
color <- findColours(breaks,palette(brewer.pal(9, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)

color <- findColours(breaks,palette(brewer.pal(9, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)

plot(catalunyaFullNumParadas, col=color, lty=1, border=NA, lwd=0.25, add=F, axes=F, pch=19,
     xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = varName, cex=0.6, box.lty=0, border = 0)


#Correlación entre la variable Gasto_tra_pub y su retardo espacial.
plot(catalunyaFullNumParadas$Gasto_tra_pub_W~catalunyaFullNumParadas$Gasto_tra_pub)

# Coeficiente de Correlación
cor.test(catalunyaFullNumParadas$Gasto_tra_pub_W,catalunyaFullNumParadas$Gasto_tra_pub)
#Pearson's product-moment correlation
#
#data:  catalunyaFullNumParadas$Gasto_tra_pub_W and catalunyaFullNumParadas$Gasto_tra_pub
#t = 15.798, df = 953, p-value < 2.2e-16
#alternative hypothesis: true correlation is not equal to 0
#95 percent confidence interval:
# 0.4037811 0.5044103
#sample estimates:
#      cor 
#0.4555497 


#Coeficiente de Correlación espacial: La I de Moran **Global**
moran.test(catalunyaFullNumParadas$Gasto_tra_pub,W,zero.policy = TRUE)
#
#Moran I test under randomisation
#
#data:  catalunyaFullNumParadas$Gasto_tra_pub  
#weights: W  n reduced by no-neighbour observations
#
#
#Moran I statistic standard deviate = 17.743, p-value < 2.2e-16
#alternative hypothesis: greater
#sample estimates:
#        Moran I statistic       Expectation          Variance 
#0.3398399774     -0.0010493179      0.0003691146 

par(mar=c(5.1, 4.1, 4.1, 2.1))
moran.plot(catalunyaFullNumParadas$Gasto_tra_pub,W,zero.policy = TRUE)

#Estimación de la desviación típica de la I de Moran por Montecarlo


#Correlación Espacial **Local**
GLocal<-localG(catalunyaFullNumParadas$Gasto_tra_pub,W,zero.policy = TRUE) # Getis-Ord Statistics
summary(GLocal)
# esta Gd de Getis sirve para hacer clusters: Valores Positivos y significativos indica valores altos 
# rodeados de valores altos; mientras que valores Negativos significativos indica valores
# bajos rodeados de valores bajos
#Tenemos valores bajos con una mediana negativa y media positiva pero no significativa, por lo que no podemos 
#concluir que tenemos valores altos rodeados de valores bajos. No hay correlación espacial. A nivel de municipio. 

#Añadimos la variable al dataset.
catalunyaFullNumParadas@data$GLocal<-as.numeric(GLocal)

#Por último, el mapa de la correlación Espacial GLocal
ColorBr="YlOrBr"
varName<-"GLocal"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 9, 
                       style="quantile",na.rm=TRUE)
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("catalunyaFullNumParadas$",noquote(varName),sep=""))), 
                                        digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)), under="menor que", over="mayor que", 
                   between="-", digits=0,cutlabels=FALSE)

plot(catalunyaFullNumParadas, col=color, lty=1, border=NA, lwd=0.25, add=F, axes=F, pch=19,
     xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = varName, cex=0.6, box.lty=0, border = 0)

par(mar=c(2,2,2,2))

#Podemos concluir que no se encuentra correlado espacialmente el gasto en transporte público con el número de paradas.
#Probablemente se encuentra correlado con la industrialización de las ciudades u otros factores.