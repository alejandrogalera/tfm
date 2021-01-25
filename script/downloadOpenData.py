import requests
import time
import json
from datetime import date

#Los datos de Opendata tienen asociados un arcGIS Id, que en el caso de las incidencias de trafico es nCKYwcSONQTkPA4K
#Esto se puede obtener consultando la URL de opendata.esri.es:
#https://opendata.esri.es/datasets/incidencias-de-tr%C3%A1fico-espa%C3%B1a/geoservice 
#Tanto la Query URL como las APIs indican el valor nCKYwcSONQTkPA4K

#Tambien se podria haber hecho uso de la API geojson: https://opendata.arcgis.com/datasets/a64659151f0a42c69a38563e9d006c6b_0.geojson


##############
# Parametros #
##############
# Estos parametros podrian setearse como argumento en linea de comandos
# Esta primera version lo simplifica seteandolo como variable global.
targetDir = "../data/opendata_esri/incid_traf/"
prefix = "incidenciasTrafico"

###############
# Generar URL #
###############
arcgisId = "nCKYwcSONQTkPA4K"
autonomia = 'CATALU%C3%91A' #sys.argv[1]

outFieldsFilter="*"  #Por defecto no se filtran los parametros de salida
whereFilter='1%3D1'  #El valor por defecto sera '1%3D1'
if (0!=len(autonomia)):
    whereFilter="autonomia%20%3D%20\'"+autonomia+"\'"

url = ('https://services1.arcgis.com/' 
      +arcgisId+ 
      '/arcgis/rest/services/incidencias_DGT/FeatureServer/0/query?where=' 
      +whereFilter+ 
      '&outFields=' 
      +outFieldsFilter+ 
      '&outSR=4326&f=json')
print(url)

#################
# Descarga Json #
#################
try:
    result = requests.get(url)
except requests.exceptions.Timeout:
    # En caso de error de Timeout se podria reintentar hasta N veces, pero por simplicidad se dejara en 1 retry.
    print("Timeout error. Retrying in 5 sec...")
    time.sleep(5)
    try:
        result = requests.get(url)
    except Exception as e:
        sys.exit("Exception: "+e)
except requests.exceptions.TooManyRedirects:
    print("TooManyRedirects error. Exiting...")
    exit(1)
except requests.exceptions.RequestException as e:
    # Excepcion generica catastrofica. Posible caida de red.
    print("Fatal request error. Check your internet connection. Exiting...")
    exit(1)
finally:
    if (200 != result.status_code):
        print("Error HTML code "+str(result.status_code))

##################
# Almacenamiento #
##################
# El nombre del fichero se formara con el prefijo y la fecha YYYYMMDD.
todayYYYYMMDD = date.today().strftime("%Y%m%d")
filename = targetDir.rstrip("/")+"/"+prefix+todayYYYYMMDD+".json"
try:
    with open(filename, "w") as fout:
        fout.write(json.dumps(result.json()))
    fout.close()
except Exception as e:
    print("Error writting "+filename+". Exception "+str(e))
    exit(2)
#finally:

print("Saved "+filename)
