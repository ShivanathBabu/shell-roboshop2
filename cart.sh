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

dnf module disable nodejs -y &>>$Log_file
validate $? "disable nodejs"

dnf module enable nodejs:20 -y &>>$Log_file
validate $? "enable nodejs"

dnf install nodejs -y &>>$Log_file
validate $? "install nodejs"

id roboshop
if [ $? -ne 0 ]
then 
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_file
validate $? "user create"
else
echo -e "already user create $y skipping $n"
fi

mkdir -r /app
validate $? "creating app directory"

curl -o /tmp//cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$Log_file
validate $? "downloading"

rm -rf /app/*
cd /app
unzip /tmp/cart.zip &>>$Log_file
validate $? "Installing dependencies"

npm install
validate $? "installing npm"

cp $script_dir/cart.service  /etc/systemd/system/cart.service
validate $? "copying Downloading"

systemctl daemon-reload
systemctl enable cart
systemctl start cart
