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
echo -e "$g you are in root access" | tee -a $Log_file
fi

validate(){
if [ $1 -eq 0 ]
then
 echo -e "$2.. $g success" | tee -a $Log_file
 else
 echo -e "$2... $r failure" | tee -a $Log_file
 exit 1
 fi
}

dnf module disable nginx -y &>>$Log_file
validate $? "disable nginx"

dnf module enable nginx:1.24 -y &>>$Log_file
validate $? "enabling nginx"

dnf install nginx -y &>>$Log_file
validate $? "install nginx"

systemctl enable nginx &>>$Log_file
systemctl start nginx &>>$Log_file
validate $? "Starting Nginx"


rm -rf /usr/share/nginx/html/* &>>$Log_file
validate $? "removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$Log_file
validate $? "downloading"

cd /usr/share/nginx/html &>>$Log_file
unzip  /tmp/frontend.zip
validate $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$Log_file
validate $? "remove default content"

cp $script_dir/nginx.conf /etc/nginx/nginx.conf
validate $? "Copying nginx.conf"

systemctl restart nginx 
validate $? "restarting nginx" 




