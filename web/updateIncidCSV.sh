#!/bin/bash
export BOTO_CONFIG=~/.boto
export CLOUDSDK_PYTHON="/usr/bin/python"
gsutil cp gs://agaleratfm-bucket/incid_traf/incid_traf_latest.csv .
