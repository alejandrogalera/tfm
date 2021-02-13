#!/bin/bash
CLUSTER_NAME=agaleratfm-cluster
BUCKET_NAME=agaleratfm-bucket
PROJECT_ID=eloquent-theme-304023
MAX_AGE=800000s
#Region cannot be global for image-version 2.0 or higher: https://kinsta.com/knowledgebase/google-cloud-data-center-locations/
#REGION=global
REGION=europe-west1
#IMAGE_VERSION=1.4-debian9 #Uses Hadoop 2.9, Spark 2.4
IMAGE_VERSION=1.5-ubuntu18 #Uses Hadoop 3.2, Spark 3.1
PROPERTIES="spark:spark.jars.packages=graphframes:graphframes:0.7.0-spark2.3-s_2.11"
#OPTIONAL_COMPONENTS=DOCKER
OPTIONAL_COMPONENTS=ANACONDA,JUPYTER
MACHINE_TYPE=n1-standard-2

gcloud dataproc clusters create $CLUSTER_NAME --region $REGION --bucket $BUCKET_NAME --enable-component-gateway \
   --master-boot-disk-size=500 --master-boot-disk-type=pd-ssd --master-machine-type $MACHINE_TYPE --num-masters 1 \
   --num-workers 2 --worker-machine-type $MACHINE_TYPE --worker-boot-disk-size=100 \
   --image-version $IMAGE_VERSION --properties $PROPERTIES --optional-components DOCKER --max-age $MAX_AGE --project ${PROJECT_ID}
