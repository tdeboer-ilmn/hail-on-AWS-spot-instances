# Hail on Amazon EMR: `cloudformation` tool with spot instances

This `cloudformation` tool  (MAC and Linux compatible) creates an EMR cluster using [spot instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html), a cost effective option  (using a bid price) to deploy clusters. Once your cluster is up and running it will have both the latest [**Hail 0.2**](https://www.hail.is) version and `JupyterNotebook` installed.

## IMPORTANT: Software requirements

This tool requires the following programs to be previously installed in your computer:
* Python3, pip and some additional python libraries
* Amazon's `Command Line Interface (CLI)` utility

To install the required software  open a terminal and execute the following:

#### For MAC
```bash
# Installs homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# Installs python3
brew install python3
# Upgrades pip
pip install --upgrade pip
#Installs additional libraries
pip install boto3 pandas botocore paramiko pyyaml -q
# Installs AWS CLI
brew install awscli
```

#### For Ubuntu
```bash
# Installs Linuxbrew
sudo apt-get -y install build-essential curl file git
echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
# Installs python3
brew install python3
# Upgrades pip
pip install --upgrade pip
#Installs additional libraries
pip install boto3 pandas botocore paramiko pyyaml -q
# Installs AWS CLI
brew install awscli
```

## Before getting started

This tool is executed from the terminal/command line using Amazon's `CLI` utility. Before spinning gears, make sure you have:

a) **A configured `CLI` account**. From the terminal execute `aws configure`, [click here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for additional information. If your `CLI` account has been previously configured, the tool will use such configuration by default. If you want to re-configure and use a specific account or a different user, execute `aws configure` and re-configure your account

b) **A valid EC2 key pair**. Click [here]( https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) to learn more on how to create and use your key

### How to use this `cloudformation` tool

1. Open a terminal and clone this repository: `git clone https://github.com/hms-dbmi/hail-on-AWS-spot-instances`

2. Change directories: `cd hail-on-AWS-spot-instances/src`

3. Using the text editor of your preference (sublime, atom, vi, emacs, etc) update the configuration file `hail02_EMR.yaml` as per the instructions below. This file is your gateway to properly spinning a cluster and it requires specific elements to successfully create your working cluster. Before heading to step **4**, follow the instructions explained beneath.

    #### Instructions to properly configure your `hail02_EMR.yaml` file

    This file will be used to provide the necessary information to create the cluster (do not change the name of the file). Give a name to your `EMR_CLUSTER_NAME` and add meaningful information by properly identifying your `EC2_NAME_TAG`, `OWNER_TAG` and `PROJECT_TAG`. The file in the repo is defaulted to region `us-east-1`, one `m4.large` master node and two `r4.4xlarge` worker nodes.

    ```yaml
    config:
      EMR_CLUSTER_NAME: "my-hail-02-cluster" # Give a name to your EMR cluster
      EC2_NAME_TAG: "my-hail-EMR" # Adds a tag to the individual EC2 instances
      OWNER_TAG: "emr-owner" # EC2 owner tag
      PROJECT_TAG: "my-project" # Project tag
      REGION: "us-east-1"
      MASTER_INSTANCE_TYPE: "m4.large"
      CORE_INSTANCE_TYPE: "r4.4xlarge"
      CORE_COUNT: "2" # Number of worker nodes
      CORE_BID_PRICE: "0.44" # Required for spot instances
      SUBNET_ID: "" # This field can be either left blank or for further security you can specify your private subnet ID in the form: subnet-1a2b3c4d
      S3_BUCKET: "s3n://my-s3-bucket/" # Specify your S3 bucket for EMR log storage
      KEY_NAME: "my-key" # Input your key name ONLY! DO NOT include the .pem extension
      PATH_TO_KEY: "/full-path-to/my-key/" # Full path to the .pem file
      WORKER_SECURITY_GROUP: "" # If empty creates a new group by default. You can also add a specific SG. See the SG link in the FAQs section
      MASTER_SECURITY_GROUP: "" # If empty creates a new group by default. You can also add a specific SG. See the SG link in the FAQs section
    ```

    3.1. Select the **EC2** instances for your `MASTER_INSTANCE_TYPE` and your `CORE_INSTANCE_TYPE`. It is recommended to use a small generic EC2 for the master, such as  `m4.large`, and more powerful EC2s (compute or memory optimized) for your worker nodes, such as `r4.4large`. See the differen EC2 types available  [here](https://aws.amazon.com/ec2/instance-types/).

    |Suggested EC2s (**`CORE_INSTANCE_TYPE`**) |
    |:-------------------------:|
    | c4.4xlarge |
    | r4.2xlarge |
    | r4.4xlarge |

    Since we are using spot instances, the worker nodes require a maximum bid price to be specified. The field `CORE_BID_PRICE` specifies the maximum cost that we will pay for each of the worker nodes. To choose an accurate and competitive bid price for your worker nodes, login to the [EMR management console](https://console.aws.amazon.com/elasticmapreduce):

    ![aws_login](./images/aws_login.png =250x)

    Click on **Go to advanced options**:

    ![advanced](./images/advanced_options.png =400x)

    You will be taken to *Step 1: Software and Steps*, click **Next**:

    ![step1](./images/step1.png =600x)

    Here, click on the instance type selection pencil **(1)** to find your worker node type. Then, hover over the **i** icon **(2)** to show the current spot price for such instance:

    ![spot_price](./images/spot_price.png =600x)

    Prices vary based on demand and by the **Subnet** with its corresponding **Availability Zone** (*subnet-053f834c* and zone *us-east-1a* in this example), where the later dictates the bid price; a good practice is to identify the current prices per subnet/zone and just go slightly above to guarantee that you will be promptly provisioned with instances. Even though you specify a certain bid price, you will still pay less if a lower price is available for your zone. The example below shows a suggested bid of $0.44 for `r4.4xlarge` instances in zones 1a and 1c:

    ![spot_price](./images/prices.png =400x)

    3.2. For your `SUBNET_ID` you can either specify the subnet from the previous step (subnet-053f834c) or you can also choose a specific one from the [VPC Dashboard](https://console.aws.amazon.com/vpc):

    ![subnet_id](./images/subnet_id.png =650x)

    For instance pricing, follow the guidelines from step **3.1**. The price is given by the **zone** where your subnet is located.

    3.3. The `S3_BUCKET` field specifies a location to store all the logs of your cluster (i.e. s3n://my-s3-bucket/). If you leave it blank ("") the log folder will be created in your **S3 root** folder. The log folder will have the same name as your automatically assigned EMR cluster ID (i.e. *j-123EMRLABEL321*)

    3.4. The `KEY_NAME` field must include the name of your key **without** the extension. If your key file is `my-key.pem` only put `my-key`. The `PATH_TO_KEY` field requires the full path pointing to the key file. **Safety remark**: make sure to previously set the proper permissions to your key file: `chmod 400 my-key.pem`.

    3.5. Go to the [VPC Dashboard](https://console.aws.amazon.com/vpc) >> Security >> Security Groups to find and specify different groups for the `WORKER_SECURITY_GROUP` and `MASTER_SECURITY_GROUP`. NOTE: if these fields are left empty (default in the configuration file) the security groups are automatically assigned. **IMPORTANT:** for security purposes, the port `8192` has to be included in the inbound rules of your `MASTER_SECURITY_GROUP`. Go to the [VPC Dashboard](https://console.aws.amazon.com/vpc) >> Security >> Security Groups and select your desired group:

      ![subnet_id](./images/security_group.png =750x)

      Click on the **Inbound Rules** tab to double check if port `8192` is on the list. To add the port click on **Edit Rules** and use one of the two configurations suggested below:

      ![subnet_id](./images/security_group_options.png =750x)

      Click [here]( https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-security-groups.html) for additional documentation on security groups.


4. Once the configuration file is properly filled and saved, go back to the terminal and from the folder `hail-on-AWS-spot-instances/src` execute the command: **`sh cloudformation_hail_spot.sh`**. The EMR cluster creation takes between 5-7 minutes (depending on EC2 availability). **DO NOT**  terminate the script execution as you will automatically get the IP address to connect to the `JypyterNotebook` in the form: **`123.456.0.1:8192`**.
You can see the live installation log executing: `tail -f /tmp/cloudcreation_log.out`, press `control + C` to exit. In case you want to connect to the master node click [here](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-connect-master-node-ssh.html) for instructions. The script will also provide the DNS to connect to the master node. The installation log at master node  of your EMR is saved at same path: `/tmp/cloudcreation_log.out`.




5. You can check the status of the EMR creation at: https://console.aws.amazon.com/elasticmapreduce. The EMR is successfully created once it gets the **Status** `Waiting` and a solid green circle next to it. After the cluster is created, allow for ~20 minutes for all the programs to be installed. All the programs are installed automatically.

## Launching the `JupyterNotebook`

To launch the  `JupyterNotebook` you need to paste the previously given IP (*`123.456.0.1:8192`* this is the master node's IP pointing to port 8192) in a browser and hit `Enter`; once you see the ![jupyter](./images/jupyter.png =40x) logo use password: **`avillach`** to login. After that, you are all set!



## FAQs and troubleshooting

Some times you may get sudden or unexpected errors. One of the reasons may be the fact that your initial spot instances can be dropped and replaced by a new instance (that's how the spot instance model works). This tool constantly --every minute-- checks for this behavior and will fix everything for you. For this and other `JupyterNotebook` glitches, you only need to restart the kernel by clicking on `Kernel` >> `Restart` or `Restart & Run All`:

![subnet_id](./images/kernel.png =550x)


For ![hail](./images/hail.png =80x) documentation visit their website: <https://hail.is/docs/0.2/index.html>