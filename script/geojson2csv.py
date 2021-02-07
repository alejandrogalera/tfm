# GeoJSON to CSV converter
# @author Alejandro Galera 2021
# @mailto alejandro.galera@gmail.com
import argparse
import json
import csv
import requests
import codecs
import magic #to know geojson encoding.
import sys
import datetime
from datetime import date
import os


def main(sysargv):
    #Process arguments
    args = processArguments(sysargv)
    print(args['input'])

    #Read json file in UTF-8 encoding
    data = getGeoJSONData(args['input'])

        #Check and print GeoJSON FeatureCollection params.
    if (not data['type'] == 'FeatureCollection'):
        print("ERROR: Incorrect GeoJson: type should be FeatureCollection and it's "+data['type'])
        exit(1)

    printGeoJSONInfo(data)
    #Get output filename from command line args or compose it with crs.properties.name
    outputFilename = getOutputFilename(args, data)

    #parseFeatures data outputFile, write header, sep, write_query_date, exclude columns
    parseFeatures(data, outputFilename, True,     ';', True,            ['xml_fragme'])


#https://stackoverflow.com/questions/436220/how-to-determine-the-encoding-of-text
def getFileEncoding(filename):
    blob = open(filename, 'rb').read()
    m = magic.open(magic.MAGIC_MIME_ENCODING)
    m.load()
    encoding = m.buffer(blob)  # "utf-8" "us-ascii" etc
    return encoding


def processArguments(sysargv):
    sys.argv = sysargv
    parser = argparse.ArgumentParser(prog="geojson2csv.py",
                                     description='Convert ArcGIS GeoJSON to CSV')
    parser.add_argument('input', nargs='?', type=str, default = sys.stdin)
    parser.add_argument('output', nargs='?', type=str)

    return vars(parser.parse_args())


def downloadFileToLocal(url):
    #Download file http://url/myfile.ext to local ./myfile.ext preserving name.
    r = requests.get(url, allow_redirects=True)
    filename = 'downloadFileToLocal.error'
    if url.find('/'):
        filename = url.rsplit('/', 1)[1]
    with open(filename, "wb") as f:
        f.write(r.content)

    return filename


def getGeoJSONData(inputfile):
    #Input can be a geojson file or an url such as
    #https://opendata.arcgis.com/datasets/a64659151f0a42c69a38563e9d006c6b_0.geojson
    if (inputfile.startswith("http")):
        inputfile = downloadFileToLocal(inputfile)

    enc = getFileEncoding(inputfile)
    with open(inputfile, encoding=enc) as fread:
        data = json.load(fread)
    return data


def printGeoJSONInfo(data):
    def printGeoJSONVar(varname, level):
        levelstring = ''.join([char*2*level for char in ' '])
        if (not data[varname] is None):
            print(levelstring+"- "+varname+": "+str(data[varname]))

    print("GeoJSON: ")
    printGeoJSONVar('type',1)
    printGeoJSONVar('name',1)
    printGeoJSONVar('crs', 1)


def getOutputFilename(args, data):
    if (args['output'] is None or 0==len(args['output'])):
        outfile = os.path.splitext(args['input'])[0]\
            +"_"+data["crs"]["properties"]["name"]+".csv"
    else:
        outfile = args['output']
    return outfile


def getCurrentDate(fullHeader):
    #query_date format: 2021-02-05T14:30:00
    now = datetime.datetime.now()
    query_date = str(now.year)+"-"\
            +str(now.month).zfill(2)+"-"\
            +str(now.day).zfill(2)+"T"\
            +str(now.hour).zfill(2)+":"\
            +str(now.minute).zfill(2)+":"\
            +str(now.second).zfill(2)
    fullHeader.append('query_date')
    return query_date


def parseFeatures(data, outfilename, enableHeader, separator, enableQueryDate, excludeCol):
    header = list(data['features'][1]['properties'].keys())
    fullHeader = header.copy()
    fullHeader.extend(['px','py'])

    if (enableQueryDate):
        query_date = getCurrentDate(fullHeader)

    #Remove excluded columns
    for excluded in excludeCol:
        fullHeader.remove(excluded)

    #CSV writer object
    with open(outfilename, mode='w') as outfile:
        csvwriter = csv.writer(outfile, delimiter=separator, quotechar='"')
        if (enableHeader is True):
            csvwriter.writerow(fullHeader)

        for feature in data['features']:
            row = []
            for colname in header:
                if (colname not in excludeCol):
                    row.append(feature['properties'][colname])

            #Get geometry point coords.
            if (feature['geometry']['type'] == 'Point') \
                and (2 == len(feature['geometry']['coordinates'])):
                row.extend(feature['geometry']['coordinates'])

            if (enableQueryDate):
                row.append(query_date)

            csvwriter.writerow(row)
    outfile.close()
    print("Written "+outfilename)

if __name__ == "__main__":
    main(sys.argv)
