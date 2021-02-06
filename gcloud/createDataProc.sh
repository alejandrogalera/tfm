#!/bin/bash
CLUSTER_NAME=agaleratfm-cluster
BUCKET_NAME=agaleratfm-bucket
PROJECT_ID=eloquent-theme-304023
MAX_AGE=800000s
REGION=global
PROPERTIES="spark:spark.jars.packages=graphframes:graphframes:0.7.0-spark2.3-s_2.11"
gcloud dataproc clusters create $CLUSTER_NAME --region $REGION --bucket $BUCKET_NAME --enable-component-gateway \
   --master-boot-disk-size=500 --master-boot-disk-type=pd-ssd --master-machine-type n1-standard-1 --num-masters 1 \
   --num-workers 2 --worker-machine-type n1-standard-1 --worker-boot-disk-size=100 \
   --image-version 1.4-debian9 --properties $PROPERTIES --optional-components ANACONDA,JUPYTER --max-age $MAX_AGE --project ${PROJECT_ID}
