# aws-rotate-backup
aws-rotate-backup was created to provide easy backups/images for multiple EC2 instances (and in different regions) and rotating the backups weekly, keeping a backup image of the instance every week for 1 month at a time. 

The script identifies AMIs tagged as Rotation 4, and de-registers them. It then identifies AMIs tagged as Rotation 3 and re-tags them Rotation 4, re-tags Rotation 2 as Rotation 3, and Rotation 1 as Rotation 2. 
The script then creates a new image of the selected EC2 instances (`tag: BACKUP`, `key: True`) and names it accordingly - `INSTANCENAME_BACKUP_DATE`

If anything disasterous happens to the server instance, it allows me to launch a (fairly) recent backup of the instance to continue from. Sometimes you may need to quickly launch the instance to compare like for like, informal experimentation etc. etc.

#Common uses include - 
Rotating weekly backups of particlar instances
	* automated backups using cron job

*You may alter the script to backup all your instances, or alter the tags used e.g. backup all instances tagged as backup=true.

#Directions for use:
`./aws-rotate-backup.sh`

You may need to apply the correct permissions to run the script. `chmod a+x ./aws-rotate-backup.sh` should do it. 

#Requirements
##Installs
This script will require the AWS command line tool (awscli) to be installed. 
For full instructions from Amazon go to https://aws.amazon.com/cli

Instructions on installing aws cli with pip `http://docs.aws.amazon.com/cli/latest/userguide/installing.html#install-with-pip`

##Configure
Instructions here for setting up aws cli  `http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html`

* config files
awscli will then need to be configured with the `aws configure` command. This will require a few things - secret access key id and secret access key.
This creates two files - a credentials file and a config file.
The credentials files will contain the secret key information for the profiles you set up. The config file will contain the region and profile names for the profiles you set up.

* instance and ami tags
From within the EC2 Management Console you will need to create a Tag Key "BACKUP", and tagged the instances to be backed up with the key "True". The scripts uses this to determine which instances to create new images of. 
In order to rotate backups you will also need to create a Tag Key "Rotation", and tag backup AMI with a key 1, 2, 3 and 4 (4 being the oldest, 1 being the most recent) The script uses these keys to de-registed the oldest AMI (4), and shift each rotation number before creating a AMI of each instance marked for backup.

##Personal Example
Below are the steps/information that apply to me - they may well be different for you. 
I backup instances from 2 regions, so when I ran 'aws configure' I set two profiles, one for each region. This can be found in the config file. 
This is usually found at `~/.aws/config`

[default]
region = eu-west-1
[profile AWSEU]
region = eu-west-1
[profile AWSVIRGINIA]
region = us-east-1


#Additional Information
*Author: Michael pearce / rootofpi.co.uk
*License Type: GNU General Public License, Version 3
*Date: 28-MARCH-2016
*Version 0.10
