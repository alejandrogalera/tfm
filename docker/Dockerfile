FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG RSTUDIO_VERSION
ARG RSTUDIO_TEMP_DIR
ARG RSTUDIO_HOME

RUN apt-get update
RUN apt-get -y install xz-utils r-base gdebi-core x11-apps wget --no-install-recommends
RUN apt-get -y install libcurl4-openssl-dev \
                       libssl-dev libprotobuf-dev libjq-dev protobuf-compiler 
RUN wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-${RSTUDIO_VERSION}-amd64.deb

#Since gdebi ask yes, instead of installing with gdebi, we install first all
#requirements with apt-get install and then dpkg -i
#RUN gdebi rstudio-${RSTUDIO_VERSION}-amd64.deb
RUN apt-get -y install gcc-9-base lib32gcc-s1 lib32gcc1 lib32stdc++6 libasan5 libatomic1 libc-dev-bin libc6-dev libc6-i386 libclang-10-dev libclang-common-10-dev libclang-dev libclang1-10 libcrypt-dev libedit2 libgc1c2 libgcc-9-dev libitm1 libllvm10 liblsan0 libobjc-9-dev libobjc4 libstdc++-9-dev libtsan0 libubsan1 libxcb-xkb1 libxkbcommon-x11-0 libxkbcommon0 linux-libc-dev manpages manpages-dev xkb-data 
RUN apt-get -y install libglu1-mesa libdbus-1-3 libnss3 libxcomposite1 libxi6 libxtst6 libasound2 --no-install-recommends
RUN dpkg -i rstudio-${RSTUDIO_VERSION}-amd64.deb

#rstudio packages
#make,gcc (build-essential) are used for executing install.packages("somepackage", repos="somerepo") in rstudio
RUN apt-get -y install r-cran-fbasics r-cran-timedate r-cran-gss r-mathlib build-essential
#DataMining requires car, corrplot, psych, questionr. questionr depends on labelled and haven
RUN apt-get -y install r-cran-car r-cran-psych r-cran-corrplot r-cran-sjlabelled r-cran-haven
RUN apt-get -y install r-cran-caret r-cran-dynlm r-cran-modelmetrics r-cran-numderiv r-cran-raster \
                       r-cran-recipes r-cran-prodlim r-cran-ipred r-cran-gtools r-cran-pwr \
                       r-cran-glmnet r-cran-epitools
RUN apt-get -y install r-cran-xts r-cran-forecast
#DataMiningII. ACP
RUN apt-get -y install r-cran-factominer r-cran-knitr r-cran-readxl r-cran-markdown r-cran-rmarkdown
RUN R -e "install.packages('pastecs',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('factoextra',dependencies=TRUE, repos='http://cran.rstudio.com/')"
#DataMiningII. Cluster.
RUN R -e "install.packages(c('cluster', 'heatmaply', 'NbClust'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
#DataMiningII. Series.
RUN R -e "install.packages(c('ggfortify', 'zoo'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
#DataMiningIII.1 Scoring
RUN R -e "install.packages(c('stargazer', 'mfx', 'scorecard', 'gmodels', 'onewaytests'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
#DataMiningIII.2 Espacial. Cartografías
RUN apt-get install -y libudunits2-dev
#RUN R -e "install.packages(c('sp', 'spdep', 'sphet', 'spatialreg', 'maptools', 'tmap', 'tmaptools', 'leaflet', 'classInt', 'gpclib'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN apt-get update
RUN apt-get -y install libgdal-dev r-cran-rgdal
#libgdal is needed to install 'sf' package, which is a 'tmap' dependency.
RUN R -e "install.packages('sp', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('spdep', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('sphet', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('spatialreg', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('maptools', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('tmap', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN apt-get -y install r-cran-v8 r-cran-rprotobuf r-cran-proto
RUN R -e "install.packages('tmaptools', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('leaflet', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('classInt', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('gpclib', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('osrm', dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('spDataLarge', repos='https://nowosad.github.io/drat/', type='source')"

#Machine Learning.
RUN R -e "install.packages(c('e1071', 'caret', 'MASS', 'dummies', 'naniar', 'nnet', 'NeuralNetTools', \
                             'ggplot2', 'plotly', 'dplyr', 'data.table', 'reshape', 'pROC', 'reshape2', \
                             'rpart', 'rpart.plot', 'rattle', 'randomForest', 'gbm', 'xgboost', \
                             'caretEnsemble', 'smartdata'), dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('h2o', type='source', repos='http://h2o-release.s3.amazonaws.com/h2o/rel-yates/2/R')"

#Aplicaciones BigData a la Empresa
RUN R -e "install.packages(c('ggeasy', 'dataPreparation', 'tictoc', 'inspectdf'), \
                           dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages(c('fastDummies', 'vtreat', 'DataExplorer', 'sqldf'), \
                           dependencies=TRUE, repos='http://cran.rstudio.com/')"

RUN apt-get -y install sudo
# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p ${RSTUDIO_HOME} && \
    echo "rstudio:x:${uid}:${gid}:Developer,,,:${RSTUDIO_HOME}:/bin/bash" >> /etc/passwd && \
    echo "rstudio:x:${uid}:" >> /etc/group && \
    echo "rstudio ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/rstudio && \
    chmod 0440 /etc/sudoers.d/rstudio && \
    chown ${uid}:${gid} -R ${RSTUDIO_HOME}

#RUN apt-get -y install apt-transport-https
#Update before upgrade to fetch new packages
RUN apt-get update
#RUN apt-get -y upgrade

RUN apt-get -y install locales
RUN locale-gen es_ES.UTF-8
RUN echo "LC_CTYPE=\"es_ES.UTF-8\""
RUN echo "LC_ALL=\"es_ES.UTF-8\""
RUN echo "LANG=\"es_ES.UTF-8\""

RUN mkdir -p ${RSTUDIO_TEMP_DIR}
RUN chmod 777 ${RSTUDIO_TEMP_DIR}
RUN chown 1000:1000 ${RSTUDIO_TEMP_DIR}
ENV HOME ${RSTUDIO_HOME}

RUN apt install default-jre -y
RUN R -e "install.packages('h2o', type='source', repos='http://h2o-release.s3.amazonaws.com/h2o/rel-zermelo/2/R')"
RUN apt-get update 
RUN apt-get install -y texlive-latex-base
RUN R -e "install.packages(c('tidyverse'), \
                           dependencies=TRUE, repos='http://cran.rstudio.com/')"
USER rstudio

ENV DISPLAY :0.0
VOLUME /tmp/.X11-unix
CMD rstudio
