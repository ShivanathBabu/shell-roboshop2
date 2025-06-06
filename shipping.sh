#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y
VALIDATE $? "Installing Maven and java"

id roboshop
if [ $? -ne 0 ]
then
useradd --system --home /app --shell /sbin/nologin --comment "system user" roboshop
VALIDATE $? "creating roboshop system user"
else
echo -e "user already created $Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "creating directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping"

rm -rf /app/*
cd /app
unzip /tmp/shipping.zip
VALIDATE $? "unzipping shipping"

mvn clean package 
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Moving and renaming Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload
VALIDATE $? "Daemon Realod"

systemctl enable shipping
VALIDATE $? "Enabling Shipping"

systemctl start shipping
VALIDATE $? "Starting Shipping"

dnf install mysql -y
VALIDATE $? "Install MySQL"

mysql -h mysql.blackweb.agency -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities'
if [ $? -ne 0 ]
then
  mysql -h mysql.blackweb.agency -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$Log_file
  mysql -h mysql.blackweb.agency -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$Log_file
  mysql -h mysql.blackweb.agency -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$Log_file
  else
     echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$Log_file
VALIDATE $? "restarting shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

