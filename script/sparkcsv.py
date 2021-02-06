import spark
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from pyspark.sql import functions as F
from pyspark.sql import Window

sc = SparkContext('local')
spark = SparkSession(sc)

df = spark.read\
          .option("header", "true")\
          .option("inferSchema", "true")\
          .csv("gs://agaleratfm-bucket/Incidencias_sin_xml_fragment.csv")
df.printSchema()

df.select('autonomia').distinct().show()

#https://stackoverflow.com/questions/33742895/how-to-show-full-column-content-in-a-spark-dataframe
df.select('causa').distinct().show(truncate=False)
#+------------------------------------------+
#|causa                                     |
#+------------------------------------------+
#| CARRETERA CORTADA A VEHÍCULOS EN TRÁNSITO|
#|ACCIDENTE                                 |
#| OTROS                                    |
#|CONGESTION                                |
#|CERRADO LUNADA                            |
#| CARRIL EN SENTIDO CONTRARIO              |
#|CIRCULACION                               |
#| ACCESOS CERRADOS                         |
#|REASFALTADO                               |
#| CARRETERA CORTADA EN ESTE SENTIDO        |
#| MODERAR VELOCIDAD                        |
#|OBRAS EN GENERAL                          |
#| RESTRICCIONES EN ACCESOS                 |
#| CARRIL DE VEHÍCULO(S) LENTO(S) CERRADO(S)|
#|LLUVIA                                    |
#|NIEBLA                                    |
#|SEÑALIZACION DE LA CALZADA                |
#|NIEVE                                     |
#|HIELO                                     |
#|MANTENIMIENTO DE PUENTES                  |
#+------------------------------------------+
dfCausas = df.select('causa').distinct() #A la web para los iconos
dfCausas.repartition(1).write.format("csv").save("gs://agaleratfm-bucket/causas.csv")

#Muy importante df.repartition(1) https://mungingdata.com/apache-spark/output-one-file-csv-parquet/

dfCat = df.filter(F.col("autonomia") == "CATALUÑA")
#https://stackoverflow.com/questions/33174443/how-to-save-a-spark-dataframe-as-csv-on-disk
dfCat.repartition(1).write.format("csv").save("gs://agaleratfm-bucket/incidencias_spark")

