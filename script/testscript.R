#args <- commandArgs(trailingOnly = TRUE)

#filename <-paste(as.character(args[1]),".txt", sep = "")

a <- 1

saveRDS(a, file = filename)


#library(htmlwidgets)

#dir.create("Z:\\new folder")

#saveWidget(scatterplot3js(x,y,z, color=rainbow(length(z))), 
#           file="Z:\\new folder\\scatterplot.html")