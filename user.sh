#!/bin/bash

userid=$(id -u)
r="\e[31m"
g="\e[32m"
y="\e[33m"
n="\e[0m"

Logs_folder="/var/log/roboshop-log"
script_name=$( echo $0 | cut -d "." -f1)
Log_file="$Logs_folder/$script_name.log"
script_dir=$PWD

mkdir -p $Logs_folder

if [ $userid -ne 0 ]
then
echo -e "$r error: please run with root access $n" | tee -a $Log_file
exit 1
else
echo -e "$g you are in root access $n" | tee -a $Log_file
fi

validate(){
if [ $1 -eq 0 ]
then
 echo -e "$2.. $g success $n" | tee -a $Log_file
 else
 echo -e "$2... $r failure $n" | tee -a $Log_file
 exit 1
 fi
}

dnf module disable nodejs -y
validate $? "disable nodejs"

dnf module enable nodejs:20 -y
validate $? "enable nodejs"

dnf install nodejs -y
validate $? "install nodejs"

id roboshop
if [ $? -ne 0 ]
then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
  validate $? "creating roboshop user"
  else
  echo -e " already user exists $y skipping $n"
  fi

mkdir -p /app
validate $? "creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip
validate $? "unzipping user"

rm -rf /app/*
cd /app
unzip /tmp/user.zip
validate $? "downloading userzip file"

npm install &>>$Log_file
validate $? "Installing Dependencies"

cp $script_dir/user.service /etc/systemd/system/user.service
validate $? "copying user.service"

systemctl daemon-reload
systemctl enable user
systemctl start user
validate $? "starting user"

