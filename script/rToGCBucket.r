options(encoding = "UTF-8")
Sys.setlocale(category="LC_ALL", locale = "es_ES.UTF8")

.libPaths()

library(googleCloudStorageR)
library(googleAuthR'')
library(googleAnalyticsR)
library(searchConsoleR)

gar_service_create(accountId = "agaleratfm-serviceaccount",
                   projectId = "eloquent-theme-304023",
                   serviceName = "googleAuthR::gar_service_create",
                   serviceDescription = "A service account created via googleAuthR")

#Configuración GCS
#https://cran.r-project.org/web/packages/googleCloudStorageR/vignettes/googleCloudStorageR.html

my_gcp_project_name <- "agaleratfm-project"
my_gcp_project_id   <- "eloquent-theme-304023"

Sys.setenv("GCS_DEFAULT_BUCKET" = "agaleratfm-bucket",
           "GCS_AUTH_FILE" = "/home/rstudio/script/eloquent-theme-304023-4eb83a51bea0.json")
gcs_setup()
3#> gcs_setup()
#ℹ ==Welcome to googleCloudStorageR v0.6.0 setup==
#  This wizard will scan your system for setup options and help you with any that are missing. 
#Hit 0 or ESC to cancel. 
#
#1: Create and download JSON service account key
#2: Setup auto-authentication (JSON service account key)
#3: Setup default bucket
#
#Selection: 2
#─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#Do you want to configure for all R sessions or just this project? 
#  
#  1: All R sessions (Recommended)
#  2: Project only
#
#Selection: 1
#─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#✓ Found: GCS_AUTH_FILE=/home/rstudio/script/key.json
#Do you want to edit this setting? 
#  
#  1: Yes
#  2: No, leave it as it is
#
#Selection: 2
#[1] FALSE
#> 
buckets <- gcs_list_buckets(my_gcp_project_id)
