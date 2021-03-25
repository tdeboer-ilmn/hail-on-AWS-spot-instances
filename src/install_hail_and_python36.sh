#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/tmp/cloudcreation_log.out 2>&1

export HAIL_HOME="/opt/hail-on-AWS-spot-instances"
export HASH="current"
export PATH=/usr/local/bin:$PATH

# Error message
error_msg ()
{
  echo 1>&2 "Error: $1"
  exit 1
}

# Usage
usage()
{
echo "Usage: install_hail_and_python.sh [-v | --version <git hash>] [-h | --help]

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
        -v|--version)   shift
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

#Fix the link for python2 (GSUTIL needs it to be python2.7)
sudo unlink /usr/bin/python2
sudo ln -s /usr/bin/python2.7 /usr/bin/python2

#Install GOOGLE cloud (on AWS !) since HAIL seems to copy something from a gs:// address
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

sudo yum install google-cloud-sdk -y

chmod 700 $HOME/.ssh/id_rsa/
KEY=$(ls ~/.ssh/id_rsa/)

for WORKERIP in `sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2`
do
   # Distribute keys to workers
   scp -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa/${KEY} ~/.ssh/authorized_keys ${WORKERIP}:/home/hadoop/.ssh/authorized_keys
done

echo 'Keys successfully copied to the worker nodes'

#Install python, git etc. on the master node
./install_python36.sh

# Add hail to the master node
sudo mkdir -p /opt
sudo chmod 777 /opt/
sudo chown hadoop:hadoop /opt
cd /opt
git clone https://github.com/tdeboer-ilmn/hail-on-AWS-spot-instances.git
cd $HAIL_HOME/src

# Compile Hail
./update_hail.sh -v $HASH

# Update to Python 3.6 (Resurrected, since easier to do here than have public bucket)
#Then for the worker nodes
for WORKERIP in `sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2`
do
   scp -i ~/.ssh/id_rsa/${KEY} install_python36.sh hadoop@${WORKERIP}:/tmp/install_python36.sh
   ssh -i ~/.ssh/id_rsa/${KEY} hadoop@${WORKERIP} 'export PATH=/usr/local/bin:$PATH'
   ssh -i ~/.ssh/id_rsa/${KEY} hadoop@${WORKERIP} "sudo ls -al /tmp/install_python36.sh"
   ssh -i ~/.ssh/id_rsa/${KEY} hadoop@${WORKERIP} "sudo /tmp/install_python36.sh &"  
done

# Set the time zone for cron updates
sudo cp /usr/share/zoneinfo/America/New_York /etc/localtime

# Get IPs and names of EC2 instances (workers) to monitor if a worker dropped  
sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2 > /tmp/t1.txt
CLUSTERID="$(jq -r .jobFlowId /mnt/var/lib/info/job-flow.json)"
aws emr list-instances --cluster-id ${CLUSTERID} | jq -r .Instances[].Ec2InstanceId > /tmp/ec2list1.txt

# Setup crontab to check dropped instances every minute and install SW as needed in new instances 
sudo echo "* * * * * /opt/hail-on-AWS-spot-instances/src/run_when_new_instance_added.sh >> /tmp/cloudcreation_log.out 2>&1 # min hr dom month dow" | crontab -

./jupyter_run.sh
