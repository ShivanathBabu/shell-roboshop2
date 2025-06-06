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

dnf install phython3 gcc python3-devel -y
validate $? "install phython3"

id roboshop
if [ $? -ne 0 ]
then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop user" roboshop
validate $? "creating user"
else
echo -e "system user already created..$y skipping $n"
fi

mkdir -p /app
validate $? "creating directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip
validate $? "downloading"

rm -rf /app/*
cd /app
unzip /tmp/payment.zip
validate $? "unzipping payment"

pip3 install -r requirements.txt
validate $? "installing requirement"

cp $script_dir/payment.service /etc/systemd/system/payment.service
validate $? "downloading"

systemctl daemon-reload
validate $? "reload"

systemctl enable payment
validate $? "enable"

systemctl start payment
validate $? "start"

