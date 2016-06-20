#!/bin/bash

configlocation="~/.aws/config"
user_profiles=($(cat $configlocation | grep 'profile ' |awk '{ print $2 ;}'|sed 's/]//'))
if [[ -z "${user_profiles[@]}" ]]; then
echo "No user profiles found. Have you configured using 'aws configure' ?"
echo "The script looked for the config file at $configlocation"
echo "Exiting."
exit
fi

echo "Which profile would you like to backup?"
COUNTER=0
for i in "${!user_profiles[@]}"
do
        printf '%s\n' "${user_profiles[$i]}"" - Press $COUNTER" 
        COUNTER=$[COUNTER + 1]
done
read choice
chosenprofile="${user_profiles[$choice]}"

if [[ -z "$chosenprofile" ]];
then echo 'Invalid selection. Exiting'
exit
fi

BackupInstanceIDS=($(aws ec2 describe-instances --profile $chosenprofile --output table --filters 'Name=tag:BACKUP,Values=True' | grep 'i-' | grep -v 'ami-\|eni-\|aki-' | awk  '{ print $4 ; }'))
BackupInstanceNAMES=($(aws ec2 describe-instances --profile $chosenprofile --output table --filters 'Name=tag:BACKUP,Values=True' | grep 'Name'|grep -v 'GroupName\|KeyName\|PrivateDnsName\|PublicDnsName\|RootDeviceName\|DeviceName\|running' | awk '{ print $4" "$5; }'|sed 's/|//g'))

if  [[ -z "${BackupInstanceIDS[@]}" ]]; then
echo "No images tagged for backup, exiting"
exit
fi

FourthRotationsIDS=($(aws ec2 describe-images --profile $chosenprofile --output table --filters 'Name=tag:Rotation,Values=4' |grep 'ami-' | awk  '{ print $4 ; }'))
if [[ -z "${FourthRotationsIDS[@]}" ]];
then echo "No fourth rotations to deregister."
else
for i in "${FourthRotationsIDS[@]}"
do
  echo "Deregistering Instance ID: $i"
  aws ec2 deregister-image --profile $chosenprofile --image-id $i
  echo "Done."
done
fi

echo "Re-tagging Rotation 3s to 4.."
ThreeToFourRotationsIDS=($(aws ec2 describe-images --profile $chosenprofile --output table --filters 'Name=tag:Rotation,Values=3' |grep 'ami-' | awk  '{ print $4 ; }'))
for i in "${ThreeToFourRotationsIDS[@]}"
do
	echo "AMI ID: $i"
        aws ec2 create-tags --profile $chosenprofile --resources  $i --tag Key=Rotation,Value=4
        echo "Done."
done

echo "Re-tagging Rotation 2s to 3.."
TwoToThreeRotationsIDS=($(aws ec2 describe-images --profile $chosenprofile --output table --filters 'Name=tag:Rotation,Values=2' |grep 'ami-' | awk  '{ print $4 ; }'))
for i in "${TwoToThreeRotationsIDS[@]}"
do
        echo "AMI ID: $i"
        aws ec2 create-tags --profile $chosenprofile --resources  $i --tag Key=Rotation,Value=3
        echo "Done."
done

echo "Re-tagging Rotation 1s to 2.."
OneToTwoRotationsIDS=($(aws ec2 describe-images --profile $chosenprofile --output table --filters 'Name=tag:Rotation,Values=1' |grep 'ami-' | awk  '{ print $4 ; }'))
for i in "${OneToTwoRotationsIDS[@]}"
do
        echo "AMI ID: $i"
        aws ec2 create-tags --profile $chosenprofile --resources  $i --tag Key=Rotation,Value=2
        echo "Done."
done
echo "Creating latest image of instances.."

NameCounter=0
now="$(date +%d_%b_%Y)"
for i in "${BackupInstanceIDS[@]}"
do
        echo "Creating image of instance ID: $i"
        echo "Naming image: ${BackupInstanceNAMES[$NameCounter]}_BACKUP_$now"
        aws ec2 create-image --instance-id  $i --no-reboot --profile $chosenprofile --name ${BackupInstanceNAMES[$NameCounter]}_BACKUP_$now
        ((NameCounter++))
        echo "Done."
done

echo "Backup rotations for $chosenprofile done."
