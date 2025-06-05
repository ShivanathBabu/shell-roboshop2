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
validate $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]
then
echo -e "$r roboshop user not yet create...$g configuring please wait $n"
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_file
validate $? "creating roboshop system user"
else
echo -e " user already exists...$y skipping $n"
fi
mkdir -p /app
validate $? "app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
validate $? "Downloading catalogue"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip
validate $? "unzipping catalogue"

npm install 
validate $? "install npm"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
validate $? "copying catalogue"

systemctl daemon-reload
systemctl enable catalogue
systemctl start catalogue
validate $? "starting catalogue"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y
validate $? "Installing mongodb client"

STATUS=$(mongosh --host mongo.blackweb.agency --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
mongosh --host mongo.blackweb.agency </app/db/master-data.js
validate $? "Loading data into MongoDB"
else
  echo -e "Data is laready loaded... $y skipping $n"
  fi
  