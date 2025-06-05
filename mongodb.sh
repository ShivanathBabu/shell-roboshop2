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

cp mongo.repo /etc/yum.repos.d/mongodb.repo
validate $? "Copying Mongodb repo"

dnf install mongodb-org -y  &>>$Log_file
validate $? "install mongodb"

systemctl enable mongod  &>>$Log_file
validate $? "Enabling MongoDB"

systemctl start mongod &>>$Log_file
validate $? "starting mongod"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$Log_file
validate $? "Editing Mongod config file "

systemctl restart mongod  &>>$Log_file
validate  $? "Restarting MongoDB"