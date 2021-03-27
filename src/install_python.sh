#!/bin/bash

export PATH=/opt/gsutil:/usr/local/bin:$PATH

sudo yum install python37 python37-devel python37-setuptools -y 
#sudo easy_install pip
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install 'setuptools>=45'

if grep isMaster /mnt/var/lib/info/instance.json | grep true; then
    sudo yum install gcc-c++ cmake git -y
    #sudo yum install gcc72-c++ -y # Fixes issue with c++14 incompatibility in Amazon Linux
    sudo yum install lz4 lz4-devel -y # Fixes issue of missing lz4
    sudo yum install openblas-devel.x86_64 lapack-devel.x86_64 -y
    # Master node: Install all
    sudo python3 -m pip install --no-cache-dir --disable-pip-version-check \
    pyserial \
    oauth \
    argparse \
    parsimonious \
    wheel \
    pandas \
    utils \
    ipywidgets \
    numpy \
    scipy \
    bokeh \
    requests \
    boto3 \
    selenium \
    pillow \
    python-magic \
    'pyspark==3.1.1' \
    'jupyterlab>3.0.0'
else 
    sudo yum install openblas-devel.x86_64 lapack-devel.x86_64 -y
    # Worker node: Install all but jupyter lab
    sudo python3 -m pip install --no-cache-dir --disable-pip-version-check \
    pyserial \
    oauth \
    argparse \
    parsimonious \
    wheel \
    pandas \
    utils \
    ipywidgets \
    numpy \
    scipy \
    bokeh \
    requests \
    boto3 \
    selenium \
    pillow \
    python-magic \
    'pyspark==3.1.1'
fi