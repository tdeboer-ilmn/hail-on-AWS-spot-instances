#!/bin/bash
export PATH=/usr/local/bin:$PATH

cd $HOME
sudo yum update -y
sudo yum install cmake git lz4-devel openblas-devel.x86_64 python3-devel -y

#Get GSUTIL installed (Don't need it on worker probably, but who cares)
wget --quiet https://storage.googleapis.com/pub/gsutil.tar.gz
sudo tar zxf gsutil.tar.gz -C /opt
sudo ln -s /opt/gsutil/gsutil /usr/local/bin/gsutil
rm gsutil.tar.gz

#Setup JAVA for HAIL installation
LATEST_JDK=`ls  /usr/lib/jvm/ | grep "java-1.8.0"`
sudo  ln -s /usr/lib/jvm/$LATEST_JDK/include /etc/alternatives/jre/include

#Setup the pyspark location
export SPARK_HOME=/usr/lib/spark
export PYSPARK_PYTHON=python3
export HAIL_HOME=/usr/local/lib/python3.7/site-packages/hail
export PYTHONPATH="$HAIL_HOME:$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-src.zip"
export SPARK_CLASSPATH=$HAIL_HOME/backend/hail-all-spark.jar

# Master node: Install hail
#Hard coding the HAIL version for now (0.2.64, since that is the last one that works with spark 3.0.1 for now)
cd /opt
sudo git clone https://github.com/hail-is/hail.git
cd hail
sudo git checkout 1ef70187dc789a6704e0e693923e2a44452eb16b
cd hail
sudo make install-on-cluster HAIL_COMPILE_NATIVES=1 SCALA_VERSION=2.12.10 SPARK_VERSION=3.0.1

cat << EOF >> ${HOME}/.bash_profile
export SPARK_HOME=/usr/lib/spark
export PYSPARK_PYTHON=python3
export HAIL_HOME=/usr/local/lib/python3.7/site-packages/hail
export PYTHONPATH="$HAIL_HOME:$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-src.zip"
export SPARK_CLASSPATH=$HAIL_HOME/backend/hail-all-spark.jar
EOF

if grep isMaster /mnt/var/lib/info/instance.json | grep true; then

    sudo python3 -m pip install --no-cache-dir --disable-pip-version-check \
    pyserial \
    oauth \
    parsimonious \
    wheel \
    pandas \
    utils \
    ipywidgets \
    scipy \
    requests \
    boto3 \
    selenium \
    pillow \
    'jupyterlab>3.0.0'

    #Setup jupyterlab and start it
    mkdir -p ${HOME}/.jupyter
    cat << EOFF > $HOME/.jupyter/jupyter_notebook_config.py
c.NotebookApp.open_browser = False
c.NotebookApp.ip='0.0.0.0' #'*'
c.NotebookApp.port = 8192 # If you change the port here, make sure you update it in the jupyter_installer.sh file as well
#Is now: tdeboer-ilmn
#Created with
# from notebook.auth import passwd
# passwd(algorithm='sha1')
c.NotebookApp.password = u'sha1:fd9cac42d6b4:aa89914827e5fabf77633ce74686ffd409ceb6b5'
c.Authenticator.admin_users = {'jupyter'}
c.LocalAuthenticator.create_system_users = True
EOFF

    JUPYTERPID=`cat /tmp/jupyter_notebook.pid` # Kill an existing Jupyter Lab if any running 
    kill $JUPYTERPID
    cd $HOME
    nohup jupyter lab >/tmp/jupyter_notebook.log 2>&1 &
    echo $! > /tmp/jupyter_notebook.pid
    echo "Started Jupyter Lab in the background."

else 
    # Worker node: Install all but jupyter lab
    sudo python3 -m pip install --no-cache-dir --disable-pip-version-check \
    pyserial \
    oauth \
    parsimonious \
    wheel \
    pandas \
    utils \
    ipywidgets \
    scipy \
    requests \
    boto3 \
    selenium \
    pillow
fi