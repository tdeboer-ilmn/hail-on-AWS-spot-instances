#!/bin/bash

export PATH=$PATH:/usr/local/bin

sudo yum install python36 python36-devel python36-setuptools -y 
sudo easy_install pip
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install 'setuptools>=45'

if grep isMaster /mnt/var/lib/info/instance.json | grep true; then
    sudo yum install gcc-c++ cmake git -y
    sudo yum install gcc72-c++ -y # Fixes issue with c++14 incompatibility in Amazon Linux
    sudo yum install lz4 lz4-devel -y # Fixes issue of missing lz4
    sudo yum install openblas-devel.x86_64 lapack-devel.x86_64 -y
    # Master node: Install all
    WHEELS="pyserial
    oauth
    argparse
    parsimonious
    wheel
    pandas
    utils
    ipywidgets
    numpy
    scipy
    bokeh
    requests
    boto3
    selenium
    pillow
    python-magic
    jupyterlab>3.0.0"
else 
    sudo yum install openblas-devel.x86_64 lapack-devel.x86_64 -y
    # Worker node: Install all but jupyter lab
    WHEELS="pyserial
    oauth
    argparse
    parsimonious
    wheel
    pandas
    utils
    ipywidgets
    numpy
    scipy
    bokeh
    requests
    boto3
    selenium
    pillow
    python-magic"
fi

for WHEEL_NAME in $WHEELS
do
    sudo python3 -m pip install $WHEEL_NAME
done
