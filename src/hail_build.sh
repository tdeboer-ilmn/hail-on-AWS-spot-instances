#!/bin/bash

# Error message
error_msg ()
{
  echo 1>&2 "Error: $1"
  exit 1
}

# Usage
usage()
{
echo "Usage: cloudformation.sh [-v | --version <git hash>] [-h | --help]

Options:
-v | --version <git hash>
    This option takes either the abbreviated (8-12 characters) or the full size hash (40 characters).
    When provided, the command uses a pre-compiled Hail version for the EMR cluster. If the hash (sha1)
    version exists in the pre-compiled list, that specific hash will be used.
    If no version is given or if the hash was not found, Hail will be compiled from scratch using the most
    up to date version available in the repository (https://github.com/hail-is/hail)

-h | --help
	Displays this menu"
    exit 1
}

# Read input parameters
while [ "$1" != "" ]; do
    case $1 in
        -v|--version)	shift
                        HASH="$1"
                        ;;
        -h|--help)      usage
                        ;;
        -*)
      					error_msg "unrecognized option: $1"
      					;;
        *)              usage
    esac
    shift
done

OUTPUT_PATH=""
HAIL_VERSION="master"
SPARK_VERSION="2.4.7"
COMPILE=true
IS_MASTER=false
GRADLE_DEPRECATION=1566593776
SELECTED_VERSION=$GRADLE_DEPRECATION
export TEST=""
export CXXFLAGS=-march=native

if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
  IS_MASTER=true
fi

while [ $# -gt 0 ]; do
    case "$1" in
    --output-path)
      shift
      OUTPUT_PATH=$1
      ;;
    --hail-version)
      shift
      HAIL_VERSION=$1
      ;;
    --spark-version)
      shift
      SPARK_VERSION=$1
      ;;
    -*)
      error_msg "unrecognized option: $1"
      ;;
    *)
      break;
      ;;
    esac
    shift
done

echo "Building Hail from $HASH"

if [ "$IS_MASTER" = true ]; then
    sudo yum install g++ cmake git -y
    sudo yum -y install gcc72-c++ # Fixes issue with c++14 incompatibility in Amazon Linux
    sudo yum install -y lz4 # Fixes issue of missing lz4
    sudo yum install -y lz4-devel
    git clone https://github.com/hail-is/hail.git
    cd hail/hail/
    git checkout $HAIL_VERSION
    GIT_HASH="$(git log --pretty=format:"%H" | grep $HASH | cut -f 1 -d ' ')"

    if [ ${#HASH} -lt 7 ]; then
    	if [ $HASH = "current" ]; then
    		echo "Hail will be compiled using the latest repository version available"
    	else
    		echo "The git hash provided has less than 7 characters. The latest version of Hail will be compiled!"
    		# exit 1
    	fi
    else
    	export TEST="$(aws s3 ls s3://tdeboer-ilmn/hail-versions/ | grep $HASH | sed -e 's/^[ \t]*//' | cut -d " " -f 2)"
    	if [ -z "$TEST" ] || [-z "$GIT_HASH" ]; then
    		echo "Hail pre-compiled version not found!"
            echo "Compiling Hail with git hash: $GIT_HASH"
            git reset --hard $GIT_HASH
            SELECTED_VERSION=`git show -s --format=%ct $GIT_HASH`
    	else
    		echo "Hail pre-compiled version found: $TEST"
            aws s3 cp s3://tdeboer-ilmn/hail-versions/$TEST $HOME/ --recursive
            GIT_HASH="$(echo $TEST | cut -d "-" -f 1)"
            git reset --hard $GIT_HASH
            COMPILE=false
    	fi
    fi

    LATEST_JDK=`ls  /usr/lib/jvm/ | grep "java-1.8.0-openjdk-1.8"`
    sudo  ln -s /usr/lib/jvm/$LATEST_JDK/include /etc/alternatives/jre/include
     

    if [ "$COMPILE" = true ]; then
        # Compile with Spark 2.4.7
        if [ $SELECTED_VERSION -ge $GRADLE_DEPRECATION ];then
          echo "Compiling with Wheel..."
          make clean
          make wheel
          HAIL_WHEEL=`ls /opt/hail-on-AWS-spot-instances/src/hail/hail/build/deploy/dist | grep "whl"`
          sudo python3 -m pip install --no-deps /opt/hail-on-AWS-spot-instances/src/hail/hail/build/deploy/dist/$HAIL_WHEEL

      else  ./gradlew -Dspark.version=$SPARK_VERSION -Dbreeze.version=0.13.2 -Dpy4j.version=0.10.6 shadowJar archiveZip
            cp $PWD/build/distributions/hail-python.zip $HOME
            cp $PWD/build/libs/hail-all-spark.jar $HOME
        fi
    fi
fi
