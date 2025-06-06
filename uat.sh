#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"  # RED
G="\e[32m"  # GREEN
Y="\e[33m"  # YELLOW
N="\e[0m"   # RESET

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo -e "$Y Script started at: $(date) $N" | tee -a $LOG_FILE

# Check for root privileges
if [ $USERID -ne 0 ]; then
  echo -e "$R ERROR: Please run this script with root access. $N" | tee -a $LOG_FILE
  exit 1
else
  echo -e "$G You are running with root access. $N" | tee -a $LOG_FILE
fi

# Validate function for status checking
VALIDATE() {
  if [ $1 -eq 0 ]; then
    echo -e "$2... $G SUCCESS $N" | tee -a $LOG_FILE
  else
    echo -e "$2... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
  fi
}

# Install NodeJS
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

# Add roboshop user if not present
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating roboshop system user"
else
  echo -e "$Y roboshop user already exists... SKIPPING $N" | tee -a $LOG_FILE
fi

# Create /app directory
mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating /app directory"

# Download and extract user code
curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user.zip"

rm -rf /app/* &>>$LOG_FILE
cd /app
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "Extracting user.zip"

# Install dependencies
npm install &>>$LOG_FILE
VALIDATE $? "Installing NodeJS dependencies"

# Copy systemd service file
cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "Copying user.service file"

# Enable and start service
systemctl daemon-reload &>>$LOG_FILE
systemctl enable user &>>$LOG_FILE
systemctl start user &>>$LOG_FILE
VALIDATE $? "Starting user service"

# Completion log
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
echo -e "$G Script completed successfully in $TOTAL_TIME seconds. $N" | tee -a $LOG_FILE
