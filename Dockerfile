FROM docker.polly.elucidata.io/elucidata/rnaseq-downstream:v0.0.3

LABEL \
    maintainer="Shreya R" \
    version="0.0.1" \
    description="Base docker to run Meta Analysis on Polly Python"

USER root

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN apt-get update && apt-get -y install parallel
RUN pip3 install --upgrade pip
RUN pip3 install polly-python
RUN pip3 install gseapy --quiet
RUN apt-get install libfftw3-dev libfftw3-doc -y
RUN R -e 'BiocManager::install("DExMA")'
RUN R -e 'BiocManager::install("EnhancedVolcano")'
RUN R -e 'BiocManager::install("cowplot")'
RUN R -e 'BiocManager::install("MetaVolcanoR")'

ENV REPOSITORY "polly-python-code"

# COPY component_GNU_generator.py ./component_GNU_generator.py
# COPY READ.key READ.key
COPY ./entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT [ "bash", "-c", "./entrypoint.sh" ]