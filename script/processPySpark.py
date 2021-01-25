# Este script python procesa los ficheros json con PySpark

import pyspark
from pyspark import SparkConf
from pyspark import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
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
srcDir = '../data/opendata_esri/incid_traf'
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


#spark = SparkSession \
#    .builder \
#    .appName("Python Spark SQL basic example") \
#    .config("spark.executor.memory", sparkMemory) \
#    .config("spark.driver.memory", sparkMemory) \
#    .getOrCreate()
#df = spark.read.json("../data/mifichero.json", multiLine=True)
#print(df.show())
#exit(1)
####################
# Lectura de datos #
####################
#if (0==len(inputFile)): 
#    inputFile = getMostRecentFileInDir(srcDir, prefix, ".json")
#print(inputFile)
inputFile = "../data/opendata_esri/incid_traf"
data = sqlContext.read.option("mode", "DROPMALFORMED").json(inputFile)
schema = sqlContext.read.json(inputFile).schema

data.printSchema()
#root
# |-- features: array (nullable = true)
# |    |-- element: struct (containsNull = true)
# |    |    |-- attributes: struct (nullable = true)
# |    |    |    |-- FID: long (nullable = true)
# |    |    |    |-- X1: double (nullable = true)
# |    |    |    |-- Y1: double (nullable = true)
# |    |    |    |-- actualizad: string (nullable = true)
# |    |    |    |-- autonomia: string (nullable = true)
# |    |    |    |-- carretera: string (nullable = true)
# |    |    |    |-- causa: string (nullable = true)
# |    |    |    |-- fechahora_: string (nullable = true)
# |    |    |    |-- hacia: string (nullable = true)
# |    |    |    |-- matricula: string (nullable = true)
# |    |    |    |-- nivel: string (nullable = true)
# |    |    |    |-- pk_final: double (nullable = true)
# |    |    |    |-- pk_inicial: double (nullable = true)
# |    |    |    |-- poblacion: string (nullable = true)
# |    |    |    |-- provincia: string (nullable = true)
# |    |    |    |-- ref_incide: string (nullable = true)
# |    |    |    |-- sentido: string (nullable = true)
# |    |    |    |-- tipo: string (nullable = true)
# |    |    |    |-- tipolocali: long (nullable = true)
# |    |    |    |-- version_in: long (nullable = true)
# |    |    |    |-- x: double (nullable = true)
# |    |    |    |-- xml_fragme: string (nullable = true)
# |    |    |    |-- xml_id: string (nullable = true)
# |    |    |    |-- xml_matche: string (nullable = true)
# |    |    |    |-- xml_pare_1: string (nullable = true)
# |    |    |    |-- xml_parent: string (nullable = true)
# |    |    |    |-- y: double (nullable = true)
# |    |    |-- geometry: struct (nullable = true)
# |    |    |    |-- x: double (nullable = true)
# |    |    |    |-- y: double (nullable = true)
# |-- fields: array (nullable = true)
# |    |-- element: struct (containsNull = true)
# |    |    |-- alias: string (nullable = true)
# |    |    |-- defaultValue: string (nullable = true)
# |    |    |-- domain: string (nullable = true)
# |    |    |-- length: long (nullable = true)
# |    |    |-- name: string (nullable = true)
# |    |    |-- sqlType: string (nullable = true)
# |    |    |-- type: string (nullable = true)
# |-- geometryType: string (nullable = true)
# |-- globalIdFieldName: string (nullable = true)
# |-- objectIdFieldName: string (nullable = true)
# |-- spatialReference: struct (nullable = true)
# |    |-- latestWkid: long (nullable = true)
# |    |-- wkid: long (nullable = true)
# |-- uniqueIdField: struct (nullable = true)
# |    |-- isSystemMaintained: boolean (nullable = true)
# |    |-- name: string (nullable = true)

#sampleDF = data.withColumnRenamed("id", "key")
df = data.select("amigo")
df.printSchema()
#causas = data.withColumn("objectIdFieldName", F.explode(data['features']['element']['attributes']))
#https://stackoverflow.com/questions/42659719/spark-2-0-flatten-json-file-to-a-csv
#causas = data.select(col("features.element.attributes.causa")).alias("causasss")
#causas.show()


#sc =SparkContext()
#spark.read("json").load("../data/incidenciasTrafico20210124.json")
