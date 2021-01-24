# Este script python procesa los ficheros json con PySpark

import pyspark
from pyspark import SparkConf
from pyspark import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql import types as T

import glob
import os
import sys

def getMostRecentFileInDir(dir, prefix, ext):
    #Para evitar doble barra seguida eliminamos la ultima si existe.
    dir = dir.rstrip('/')
    #Una vez r-stripeada se puede anyadir de forma unica.
    list_of_files = glob.glob(dir+'/'+prefix+'*'+ext) 
    latest_file = max(list_of_files, key=os.path.getctime)
    return(latest_file)


#############
# Variables #
#############
# En una posterior version, estas variables se parametrizaran como 
# argumentos en linea de comandos
srcDir = '../data'
prefix = "incidenciasTrafico"
# Por defecto, el fichero de entrada sera cadena vacia, ya que no lo 
# invocaremos por defecto con ningun parametro, en cuyo caso se 
# inicializara al mas reciente en el directorio srcDir
inputFile = '' #sys.argv[1]

################################
# Configuracion contexto Spark #
################################
# Primero configuramos el spark context SparkContext
sparkMemory = '2g' 
# Este valor sparkMemory es habitualmente en torno a 10g o mas, 
# pero para estos desarrollos en entornos locales dockerizados 
# se puede reducir teniendo en cuenta que el volumen de datos no es muy grande.
# Se trata de sentar las bases funcionales de un sistema que se adapte
# a entornos mas exigentes con una carga alta de datos cuando se desplieguen
# estos scripts en un cluster DataProc de Google Cloud Storage, por ejemplo.

conf = SparkConf()
conf.set('spark.local.dir', '/remote/data/match/spark')
conf.set('spark.sql.shuffle.partitions', '2100')
SparkContext.setSystemProperty('spark.executor.memory', sparkMemory)
SparkContext.setSystemProperty('spark.driver.memory', sparkMemory)
sc = SparkContext(appName='mm_exp', conf=conf)
sqlContext = pyspark.SQLContext(sc)


spark = SparkSession \
    .builder \
    .appName("Python Spark SQL basic example") \
    .config("spark.executor.memory", sparkMemory) \
    .config("spark.driver.memory", sparkMemory) \
    .getOrCreate()
df = spark.read.json("../data/mifichero.json", multiLine=True)
print(df.show())
exit(1)
####################
# Lectura de datos #
####################
#if (0==len(inputFile)): 
#    inputFile = getMostRecentFileInDir(srcDir, prefix, ".json")
#print(inputFile)
#data = sqlContext.read.json(inputFile)

#data.printSchema()
#causas = data.select("objectIdFieldName").distinct()
#print(causas)


#sc =SparkContext()
#spark.read("json").load("../data/incidenciasTrafico20210124.json")
