#Opción 1: Econometría a ver si hay correlación espacial del gasto en transporte público con el número de paradas de bus.
#Opción 2: Econometría a ver si hay correlación entre tamaño de población -> Gasto total municipal -> en función de la renta?


#' # Objetivo
#' Queremos estimar la ley de OKUN con datos Municipales,
#' en este caso para explicar la Tasa de Paro Municipal en función
#' de la renta percápita Municipal. Al tener datos georeferenciados
#' nos preguntaremos si en la explicación de la tasa de paro municipal
#' existen correlaciones espaciales con los municipio vecinos, y en tal caso
#' presentaremos dos modelos para intentar estimar dichos efectos espaciales

# Carga de Librerías necesarias ----
library(rgdal)
library(maptools) # leer los shapes
library(sp) # paquete de referencia de datos espaciales
library(spdep) # econometría espacial
library(sphet) # modelos de regresión espacial con heterocedasticidad
library(spatialreg) # para otros métodos de regresión espacial
# library(spse) # spse: Spatial Simultaneous Equations and Spatial Sur Model
#install.packages("spse", repos="http://R-Forge.R-project.org")


library(RColorBrewer) # paleta de colores
library(classInt)# para crear intervalos
library(scales)

library(dplyr)
library(stargazer) # tablas de resultados de moedlos de regresi?n


# Leo los Shapes ----
#' # Carga de Cartografías de los Municipios Españoles

# Leo los Shapes con `maptools`
# MUNIC_ESP<-maptools::readShapeSpatial("Munics04_GEO_ETRS89_DAT.shp",IDvar = "cod_ine", proj4string=CRS("+init=epsg:4258"))

# Leo losshape con `rgdal` desde el directorio de trabajo o específico 
#MUNIC_ESP<-readOGR( dsn= "." , layer="Munics04_GEO_ETRS89_DAT")
#MUNIC_ESP<-readOGR( dsn= getwd() , layer="Munics04_GEO_ETRS89_DAT")
MUNIC_ESP<-rgdal::readOGR(dsn="cartografías",layer="Munic04_ESP_GEO_ETRS89_DAT")

# primer mapa municipal
plot(MUNIC_ESP)

# El SpatialPoligonDataFrame que hemos cargado incorpora una base con datos Municipales
# Podemos consultar por ejemplo los municipios mñas ricos en la base de datos

head(MUNIC_ESP@data%>%
       arrange(desc(RENTPCAP07))%>%
       select(MUN,RENTPCAP07), 10)

# head(row.names(MUNIC_ESP@data), 10)
View(head(MUNIC_ESP@data,10))

hist(MUNIC_ESP@data$TASA_PARO)
hist(MUNIC_ESP@data$RENTPCAP07)


# compruebo si hay datos nulos

table(is.na(MUNIC_ESP@data$RENTPCAP07))
table(is.na(MUNIC_ESP@data$TASA_PARO))

# si necesitase añadir algún campo adicional
#MUNIC_ESP@data<-dplyr::left_join(MUNIC_ESP@data,tablanewdatos, by=c("CODINE"="geo_code"))
#o tambien con sp::spCbind(MUNIC_ESP@data, tablanewdatos) los rownames deben ser los mismos



# Mapas por cuantiles ----
#' # Mapas Descriptivos

# busco las coordenadas máximas y mínimas para poder representar los mapas
xmax<-max(coordinates(MUNIC_ESP)[,1])
xmin<-min(coordinates(MUNIC_ESP)[,1])

ymax<-max(coordinates(MUNIC_ESP)[,2])
ymin<-min(coordinates(MUNIC_ESP)[,2])

#Mapa de la renta percápita por cuantiles
ColorBr="YlOrBr" # mirar otras opciones en la paleta de colorBrewer (lo colores deben elgirse bien)
nombrevbles<-"RENTPCAP07"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), 9, style="quantile")
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=0), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#lo repito otra vez porque me falla a la primera No debería pero...
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=0), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#dibujo el mapa
plot(MUNIC_ESP,col = color,lty=1, border=NA,lwd=0.25, add=F,  axes=F, pch = 19,xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.70,y = 37.5,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = nombrevbles, cex=0.75, box.lty=0, border = 0)


#Mapa de la Tasa de Paro
#Para grabarlo
jpeg(file=paste0("graficoTasa de Paro.jpeg"),height=500, width = 500*1.397,bg ="transparent", quality = 100)
ColorBr="PuBuGn"
nombrevbles<-"TASA_PARO"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), 9, style="quantile")
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#lo repito para que coja bien los colores
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#mapa
plot(MUNIC_ESP,col = color,lty=1, border=NA,lwd=0.25, add=F,  axes=F, pch = 19,xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = nombrevbles, cex=0.6, box.lty=0, border = 0)

#Si lo he grabado
dev.off()
par(mar=c(5.1, 4.1, 4.1, 2.1))
#' ![](graficoTasa de Paro.jpeg) 


# Observando esos dos gráficos, ¿podría decirse que los municipios con mayor nivel de Renta son los que tienen menores tasas de paro?


##################################################
# Creo la matriz de pesos----
#' # La matriz de pesos espaciales



#### Por contiguidad de la Reina
?poly2nb
list.queen<-poly2nb(MUNIC_ESP, queen=TRUE)
W<-nb2listw(list.queen, style="W", zero.policy=TRUE)

hist(card(list.queen)) # histograma del número de vecinos
summary(card(list.queen))

# mapa de contigüidades
par(mar=c(0,0,0,0))
plot(MUNIC_ESP, border="grey")
plot(W,coordinates(MUNIC_ESP),add=TRUE)
par(mar=c(5.1, 4.1, 4.1, 2.1))

par(mar=c(0,0,0,0))
plot(MUNIC_ESP, border="grey",xlim=c(-0.5,0.5), ylim=c(37,40))
plot(W,coordinates(MUNIC_ESP), add=TRUE)
par(mar=c(5.1, 4.1, 4.1, 2.1))




###############[SALTAR ESTA PARTE]
###### PARA ESTIMAR LA MATRIZ DE PESOS POR VECIONS CERCANOS
#coords <- coordinates(MUNIC_ESP)
#col.knn <- knearneigh(coords, k=4)

#par(mar=c(0,0,0,0))
#plot(MUNIC_ESP, border="grey", xlim=c(-0.5,0.5), ylim=c(37,40))
#plot(knn2nb(col.knn), coords, add=TRUE)
#title(main="K nearest neighbours, k = 4")
#par(mar=c(5.1, 4.1, 4.1, 2.1))

#Knn4<-knn2nb(col.knn)
#dists <- nbdists(Knn4, coords)
#W <- nb2listw(Knn4, glist=dists, style="W",zero.policy=TRUE)

#hist(card(Knn4)) # histograma del número de vecinos
#summary(card(Knn4))


#par(mar=c(0,0,0,0))
#plot(MUNIC_ESP, border="grey",xlim=c(-0.5,0.5), ylim=c(37,40))
#plot(W,coordinates(MUNIC_ESP), add=TRUE)
#par(mar=c(5.1, 4.1, 4.1, 2.1))



###### PARA LA ESTIMACION DE LA MATRIZ DE PESOS POR DISTANCIA
#coords<-coordinates(MUNIC_ESP)

# Distancia entre 0 y la distancia máxima del más cercano (Asegura que todos tienen al menos uno)
#all.linked <- max(unlist(nbdists(knn2nb(knearneigh(coords)), coords)))
#W_dist<-dnearneigh(coords,0,all.linked,longlat = FALSE)

# Distancia entre 0 y 15 Kms
#W_dist<-dnearneigh(coords,0,15,longlat = TRUE) # distancia en Km


#hist(card(W_dist)) # histograma del número de vecinos

#par(mar=c(0,0,0,0))
#plot(MUNIC_ESP, border="grey",xlim=c(-0.5,0.5), ylim=c(37,40))
#plot(W_dist,coordinates(MUNIC_ESP), add=TRUE)
#par(mar=c(5.1, 4.1, 4.1, 2.1))



#dists <- nbdists(W_dist, coords)
#W <- nb2listw(W_dist, glist=dists, style="W",zero.policy=TRUE)

#par(mar=c(0,0,0,0))
#plot(MUNIC_ESP, border="grey",xlim=c(-0.5,0.5), ylim=c(37,40))
#plot(W,coordinates(MUNIC_ESP), add=TRUE)
#par(mar=c(5.1, 4.1, 4.1, 2.1))


##############################################
##############################################
# Una vez que he estimado W (lista) de la forma que nos parezca más adecuada
# Puedo convertirla en matriz para calcular la matriz de pesos y
# y los retardos espaciales

# Para este ejemplo me quedo con la matriz de vecidandes tipo REINA

# y ahora obtengo WM en forma de matriz para calcular retardos

WM<-listw2mat(W)
dim(WM)

#creo el retardo espacial de la tasa de paro ----
#' # Retardos Espaciales

MUNIC_ESP@data$TASA_PAROW<-(WM%*%MUNIC_ESP@data$TASA_PARO)[,1]

summary(MUNIC_ESP@data$TASA_PARO)
summary(MUNIC_ESP@data$TASA_PAROW)

table(is.na(MUNIC_ESP@data$TASA_PAROW))

par(mar=c(5.1, 4.1, 4.1, 2.1))

hist(MUNIC_ESP@data$TASA_PARO, nclass = 20, col=3, freq = FALSE)
hist(MUNIC_ESP@data$TASA_PAROW, nclass=20, col=2, freq=FALSE)

plot(density(MUNIC_ESP@data$TASA_PAROW), col="red", lwd=2, main="")
lines(density(MUNIC_ESP@data$TASA_PARO), col="darkgreen", lwd=2)
legend("topright",col=c("red","darkgreen"),legend = c("PAROW","PARO"), lty=1,lwd=2)



jpeg(file=paste0("graficoTasa de ParoW.jpeg"),height=500, width = 500*1.397,bg ="transparent")
ColorBr="PuBuGn"
nombrevbles<-"TASA_PAROW"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), 9, style="quantile")
color <- findColours(breaks,palette(brewer.pal(9, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
color <- findColours(breaks,palette(brewer.pal(9, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
plot(MUNIC_ESP,col = color,lty=1, border=NA,lwd=0.25, add=F,  axes=F, pch = 19,xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = nombrevbles, cex=0.6, box.lty=0, border = 0)
dev.off()

#' ![](graficoTasa de ParoW.jpeg) 

# correlación espacial----
#' # Correlación entre una variable y su retardo espacial
 
plot(MUNIC_ESP$TASA_PAROW~MUNIC_ESP$TASA_PARO)

# Coeficiente de Correlación
cor.test(MUNIC_ESP$TASA_PAROW,MUNIC_ESP$TASA_PARO)

# Coeficiente de Correlación espacial: La I de Moran **Global**
moran.test(MUNIC_ESP$TASA_PARO,W,zero.policy = TRUE)

par(mar=c(5.1, 4.1, 4.1, 2.1))

moran.plot(MUNIC_ESP$TASA_PARO,W,zero.policy = TRUE)

# Estimación de la desviación típica de la I de Moran por Montecarlo
# moran.mc(MUNIC_ESP$TASA_PARO,W,zero.policy = TRUE,nsim=1000) #Estimaci?n de la I de moran con simulaci?n

# Correlación Espacial **Local**

GLocal<-localG(MUNIC_ESP$TASA_PARO,W,zero.policy = TRUE) # Getis-Ord Statistics
summary(GLocal)
# esta Gd de Getis sirve para hacer clusters: Valores Positivos y significativos indica valores altos 
# rodeados de valores altos; mientras que valores Negativos significativos indica valores
# bajos rodeados de valores bajos

MUNIC_ESP@data$GLocal<-as.numeric(GLocal)

# Mapa de la correlación Espacial
ColorBr="PuBuGn"
nombrevbles<-"GLocal"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), 9, style="quantile",na.rm=TRUE)
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
plot(MUNIC_ESP,col = color,lty=1, border=NA,lwd=0.25, add=F,  axes=F, pch = 19,xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = nombrevbles, cex=0.6, box.lty=0, border = 0)

par(mar=c(2,2,2,2))


# Otra forma de estimar la correlación espacial Local es con el I de Moral

lmoran<-localmoran(MUNIC_ESP$TASA_PARO,W,zero.policy = TRUE)  # I de moran local (para cada poligono)
summary(lmoran) # la quinta columna proporciona el pValor 
# ojo aquí el valor de la I indica si la autocorrelación es positiva o negativa, por eso para hacer 
# cluster se recurre a los mapas LISA en función del cuadrante del
# scatterplot de Moran... explicados más alante


MUNIC_ESP@data$lmoran<-lmoran[,5]

MUNIC_ESP@data$quad_sig <- NA


#' ### Mapa de las correlaciones espaciales locales y significativas
#' mapas LISA-Local Indicator of Spatial Association


MUNIC_ESP@data$TASA_PARO_TIP<-scale(MUNIC_ESP@data$TASA_PARO)
MUNIC_ESP@data$TASA_PAROW_TIP<-scale(MUNIC_ESP@data$TASA_PAROW)
hist(MUNIC_ESP@data$TASA_PAROW_TIP)

# high-high quadrant
MUNIC_ESP@data$quad_sig[(MUNIC_ESP@data$TASA_PARO_TIP >= 0 & MUNIC_ESP@data$TASA_PAROW_TIP >= 0 & 
                                 MUNIC_ESP@data$lmoran <= 0.05)] <- "high-high"
# low-low quadrant
MUNIC_ESP@data$quad_sig[(MUNIC_ESP@data$TASA_PARO_TIP <= 0 & 
                                 MUNIC_ESP@data$TASA_PAROW_TIP <= 0 & 
                                 MUNIC_ESP@data$lmoran <= 0.05)] <- "low-low"

# high-low quadrant
MUNIC_ESP@data$quad_sig[(MUNIC_ESP@data$TASA_PARO_TIP >= 0 & 
                                 MUNIC_ESP@data$TASA_PAROW_TIP <= 0 & 
                                 MUNIC_ESP@data$lmoran <= 0.05)] <-  "high-low"


# low-high quadrant
MUNIC_ESP@data$quad_sig[(MUNIC_ESP@data$TASA_PARO_TIP <= 0 & 
                                 MUNIC_ESP@data$TASA_PAROW_TIP >= 0 & 
                                 MUNIC_ESP@data$lmoran <= 0.05)] <-  "low-high"

# non-significant observations
MUNIC_ESP@data$quad_sig[MUNIC_ESP@data$lmoran > 0.05] <-  "not signif."


names(table(MUNIC_ESP@data$quad_sig))


MUNIC_ESP@data$quad_sig <- as.factor(MUNIC_ESP@data$quad_sig)


nombrevbles<-"quad_sig"
par(mar=c(0,0,0,0))
palette(brewer.pal(n = 5, name = "Dark2"))
plot(MUNIC_ESP,col = eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))),
     lty=1, border=NA,lwd=0.25, add=F,  axes=F, pch = 19,xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37, legend=names(table(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))))),
       fill=palette(brewer.pal(n = 5, name = "Set2")), title = nombrevbles, cex=0.6, box.lty=0, border = 0)
par(mar=c(2,2,2,2))





# correlación tasa de paro con Rentapercápita----

cor.test(MUNIC_ESP$TASA_PARO,MUNIC_ESP$RENTPCAP07)
plot(MUNIC_ESP$TASA_PARO~MUNIC_ESP$RENTPCAP07)

#install.packages("corrplot")
#library(corrplot)
#corrplot(correlacion, method="color")
#correlacion<-cor(MUNIC_ESP@data[,c(58, 9:28)],use = "pairwise.complete")
#correlacion[1,]


# modelo regresion sin efectos espaciales
library(lmtest) # para realizar diferetes test sobre regresión lineal

modelo.lm<-lm(TASA_PARO~RENTPCAP07, MUNIC_ESP@data)
summary(modelo.lm)

#Índice de Moran sobre los residuos.
moran.A<-lm.morantest(modelo.lm, W, alternative="two.sided", zero.policy=TRUE)
print(moran.A)


# Como on datos de sección cruzada es posible tener problemas de Heterocedasticidad
#lmtest::bptest(modelo.lm)# Ho: Ausencia de Heteroscedasticidad

#library(sandwich)
#modelo.lm.ro<-lmtest::coeftest(modelo.lm, vcov = vcovHC(modelo.lm, "HC0"))    # robust; HC0 
#stargazer(modelo.lm, modelo.lm.ro, type="text")

### test sobre efectos espaciales en los residuos

# Guardo los residuos de cada Municipio
MUNIC_ESP@data$lm.res<-resid(modelo.lm)

ColorBr="PuBuGn"
nombrevbles<-"lm.res"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), 9, style="quantile")
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
plot(MUNIC_ESP,col = color,lty=1, border=NA,lwd=0.25, add=F,  axes=F, pch = 19,xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = nombrevbles, cex=0.6, box.lty=0, border = 0)

par(mar=c(2,2,2,2))


#Si los residuos fuesen un ruido blanco deberían distribuirse de anera uniforma en todo el teritorio
# no debería observarse relación espacial



# Indice de Moran sobre los residuos
moran.lm<-lm.morantest(modelo.lm, W, alternative="two.sided", zero.policy=TRUE)
print(moran.lm)



####################################################

#' ## Modelos de ecnometría Espacial
formula_lm<-formula(modelo.lm)


## SAR: Spatial lag Model ---------------



# Se estima por Método Generalizado de los momentos (Ojo que tarda)
#sar.lm<-lagsarlm(formula_lm, data=MUNIC_ESP@data, W,zero.policy = TRUE)
#summary(sar.lm)

#para corregir por heteroscedasticidad habría que utilizar la librería sphet
#sar.lm<-sphet::spreg(formula_lm, data=MUNIC_ESP@data, listw=W, model="lag", het=TRUE)

# o por Mínimos Cuadrados en dos etapas

sar.tslm<-stsls(formula_lm, data = MUNIC_ESP@data, W, zero.policy = TRUE,
             na.action = na.fail, robust = TRUE, HC="HC1", legacy=FALSE, W2X = TRUE)
summary(sar.tslm)

#De la pregunta 12 de la evaluación.
modelo.B<-stsls(TASA_PARO~RENTPCAP07, data = MUNIC_ESP@data, W, zero.policy = TRUE,
                na.action = na.fail, robust = TRUE, HC="HC1", legacy=FALSE, W2X=TRUE)
moran.B<-moran.test(resid(modelo.B), W, alternative="greater", zero.policy=TRUE)
print(moran.B)
?stsls

# residuos del Spatial lag model

# sar.res<-resid(sar.lm)
sar.res<-resid(sar.tslm)
names(sar.res)


# ¿En qué municipios te equivocas más y en qué municipios te equivocas menos, se ha eleiminado el problema de la 
# autocorrelación espacial?

MUNIC_ESP@data$sar.res<-resid(sar.tslm) #residual Para poder dibujar los residuos

ColorBr="PuBuGn"
nombrevbles<-"sar.res"
par(mar=c(0,0,0,0))
breaks<-classIntervals(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), 9, style="quantile")
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
plot(MUNIC_ESP,col = color,lty=1, border=NA,lwd=0.25, add=F,  axes=F, pch = 19,xlim=c(xmin,xmax), ylim=c(ymin,ymax))
legend(x = -0.75,y = 37,fill=attr(leg, "palette"),
       legend=names(attr(leg,"table")),
       title = nombrevbles, cex=0.6, box.lty=0, border = 0)

par(mar=c(2,2,2,2))



# Indice de Moran sobre los residuos

moran.test(resid(sar.tslm), W, alternative="greater", zero.policy=TRUE)
moran.plot(resid(sar.tslm),W,zero.policy = TRUE)
moran.mc(resid(sar.tslm),W,zero.policy = TRUE, nsim=1000) #Estimaci?n de la I de moran con simulaci?n


#  Impactos (OJO QUE TARDA MUCHO)
# impacts(sar.lm, listw=W,zero.policy = TRUE )
# impacts(sar.tslm, empirical = TRUE,listw=W,zero.policy = TRUE )


# Posible explicación al fenómeno observado:

boxplot(MUNIC_ESP@data$RENTPCAP07~cut(MUNIC_ESP@data$POB_2016,breaks = c(-Inf, 10000,25000,50000,100000,500000, Inf))) 
boxplot(MUNIC_ESP@data$TASA_PARO~cut(MUNIC_ESP@data$POB_2016,breaks = c(-Inf, 10000,25000,50000,100000,500000, Inf)))        

datosCutPob= MUNIC_ESP@data %>% 
        group_by(cut(POB_2016,breaks = c(-Inf, 10000,25000,50000,100000,500000, Inf))) %>% 
        summarise(mediaRenta=mean(RENTPCAP07, na.rm=TRUE), mediaTASAPARO=mean(TASA_PARO, na.rm=TRUE))

plot(mediaTASAPARO~mediaRenta, data=datosCutPob, pch=19 )
 abline(lm(mediaTASAPARO~mediaRenta, data=datosCutPob))



 
####################################################################################################
#' ***
#' # Otros Modelos Espaciales - Ver Tabla en la presentación 


# Estimación de Todos los modelos con librería spatialreg

# m=0 MCO ###########
#modelo.lm<-lm(TASA_PARO~RENTPCAP07, MUNIC_ESP@data)
#summary(modelo.lm)
#AIC(modelo.lm)
#save(lagsarmodel, file="m0_modelo.lm.Rdata")

#formula_lm<-formula(modelo.lm)


# m=1 Spatial lag model ############
#lagsarmodel<-spatialreg::lagsarlm(formula_lm, data = MUNIC_ESP@data, W, zero.policy = TRUE,
#                                  na.action = na.fail,Durbin = FALSE)
#summary(lagsarmodel)
#save(lagsarmodel, file="m1_lagsarmodel.Rdata")


# m=2 Spatial Durbin model ###########
#SpatialDurbin<-spatialreg::lagsarlm(formula_lm, data = MUNIC_ESP@data, W, zero.policy = TRUE,
#                                    na.action = na.fail,Durbin = TRUE)
#summary(SpatialDurbin)
#save(SpatialDurbin, file="m2_SpatialDurbin.Rdata")


# m=3 Spatial laged Xmodel ###########
#SpatialLagX<-spatialreg::lmSLX(formula_lm, data = MUNIC_ESP@data, W, zero.policy = TRUE,
#                               na.action = na.fail, Durbin = TRUE)
#summary(SpatialLagX)
#AIC(SpatialLagX)
#save(SpatialLagX, file="m3_SpatialLagX.Rdata")


# m=4 Spatial error model ###########
#Spatialerror<-spatialreg::errorsarlm(formula_lm, data = MUNIC_ESP@data, W, zero.policy = TRUE,
#                                     na.action = na.fail,Durbin = FALSE)
#summary(Spatialerror)
#save(Spatialerror, file="m4_Spatialerror.Rdata")


# m=5 Spatial Durbin error model ###########
#SpatialDurbinerror<-spatialreg::errorsarlm(formula_lm, data = MUNIC_ESP@data, W, zero.policy = TRUE,
#                                           na.action = na.fail,Durbin = TRUE)
#summary(SpatialDurbinerror)
#save(SpatialDurbinerror, file="m5_SpatialDurbinerror.Rdata")


# m=6 Spatial SACSAR model (Kalejian-Prucha) ###########
#SpatialSACSAR<-spatialreg::sacsarlm(formula_lm, data = MUNIC_ESP@data, W, zero.policy = TRUE,
#                                    na.action = na.fail,Durbin = FALSE)
#summary(SpatialSACSAR)
#save(SpatialSACSAR, file="m6_SpatialSACSAR.Rdata")


# m=7 Spatial SACSAR Durbin model (Manski) ###########
#SpatialSACSARDurbin<-spatialreg::sacsarlm(formula_lm, data = MUNIC_ESP@data, W, zero.policy = TRUE,
#                                          na.action = na.fail,Durbin = TRUE)
#summary(SpatialSACSARDurbin)
#save(SpatialSACSARDurbin, file="m7_SpatialSACSARDurbin.Rdata")


###########################################################################
## SEM: Spatial Error Model Por mínimos Cuadrados Generalizado Factibles (Tarda menos)

# modelo 4 SEM Spatial erro model
# por Método Generalizado de los momentos (Ojo que tarda)
#errorsar.lm<-errorsarlm(formula_lm, data=MUNIC_ESP@data, W,zero.policy = TRUE)
#summary(errorsar.lm)

# o corrigiendo por heterocedassticidad
#errorsar.lm<-sphet::spreg(formula_lm, data=MUNIC_ESP@data, listw=W, model="error", het=TRUE)
#summary(errorsar.lm)


# o por Feasible Generalized Least Squares (GLS) with the function GMerrorsar.
#errorsar.fgls<-GMerrorsar(formula_lm, data=MUNIC_ESP@data, W,zero.policy = TRUE)
#summary(errorsar.fgls)


# PARA HACER GRAFICO DE MUNICIPIOS
# ¿En qué municipios te equivocas más y en qué municipios te equivocas menos?

#MUNIC_ESP@data$errorsar.res<-resid(errorsar.lm) #residual PAra poder dibujar los residuos
#MUNIC_ESP@data$errorsar.res<-resid(errorsar.fgls) #residual PAra poder dibujar los residuos

#ColorBr="PuBuGn"
#nombrevbles<-"errorsar.res"
#par(mar=c(0,0,0,0))
#breaks<-classIntervals(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), 9, style="quantile")
#color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
#leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
#                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
#color <- findColours(breaks,palette(brewer.pal(5, ColorBr)))
#leg <- findColours(classIntervals(round(eval(parse(text=paste("MUNIC_ESP$",noquote(nombrevbles),sep=""))), digits=2), 5, style="quantile"),
#                   palette(brewer.pal(5, ColorBr)),under="menor que", over="mayor que", between="-", digits=0,cutlabels=FALSE)
#
#plot(MUNIC_ESP,col = color,lty=1, border=NA,lwd=0.25, add=F,  axes=F, pch = 19,xlim=c(xmin,xmax), ylim=c(ymin,ymax))
#legend(x = -0.75,y = 37,fill=attr(leg, "palette"),
#       legend=names(attr(leg,"table")),
#       title = nombrevbles, cex=0.6, box.lty=0, border = 0)

#par(mar=c(2,2,2,2))


# Indice de Moran sobre los residuos
#moran.test(resid(errorsar.fgls), W, alternative="greater", zero.policy=TRUE)
#moran.plot(resid(errorsar.fgls),W,zero.policy = TRUE)
#moran.mc(resid(errorsar.fgls),W,zero.policy = TRUE, nsim=1000) #Estimaci?n de la I de moran con simulaci?n

#############################################################################

# RESUMEN de MODELOS
#summary(modelo.lm)
#summary(sar.lm)
#summary(sar.tslm)
#summary(errorsar.lm)
#summary(errorsar.fgls)



# y comó saber qué modelo es mejor???????
#' ## Test sobre los modelos espaciales (ANSELIN)
# test LM para elegir entre el Spatial LAg (SAR) y el Spatial ERR(SEM)
#LM<-lm.LMtests(modelo.lm, W, test="all", zero.policy=TRUE)
#print(LM)


# Impactos (OJO QUE TARDA MUCHO)
#impacts(sar.lm, listw=W,zero.policy = TRUE )
#impacts(sar.tslm, listw=W,zero.policy = TRUE )


############################################################################
####### OTROS MODELOS


# GMM SARAR
#gs2sls <- gstsls(form, data = data_set,listw = lw)
#sarar_het<-spreg(form, data = data_set,listw = lw, model = "sarar", het=TRUE)

# GMM lag endog
#spreg_lag_endog_het<-spreg(form1, data = data_set,  listw = lw, endog = ~police, instruments = ~elect, model = "lag", het=TRUE, lag.instr = TRUE)

# GMM error endog
#spreg_error_endog_het<-spreg(form1, data = data_set,  listw = lw, endog = ~police, instruments = ~elect, model = "error", het=TRUE, lag.instr = TRUE)

# GMM sarar endog
#spreg_sarar_endog_het<-spreg(form1, data = data_set,  listw = lw, endog = ~police, instruments = ~elect, model = "sarar", het=TRUE, lag.instr = TRUE)


# ML lag mirar library(McSpatial) y el ejemplo en Biban Piras

# library(spse) # Spatial Simultaneous Equations and Spatial Sur Model


 
 ########### Pregunta 10 evaluación 
 
 lista<-poly2nb(MUNIC_ESP)
 W<-nb2listw(lista, style="W", zero.policy=TRUE)
 
 par(mar=c(0,0,0,0))
 plot(MUNIC_ESP, border="grey",xlim=c(-0.5,0.5), ylim=c(37,40))
 plot(W,coordinates(MUNIC_ESP), add=TRUE)
 par(mar=c(5.1, 4.1, 4.1, 2.1))
 
 
 
 #####Pregunta 11 evaluación
 install.packages('ape')
