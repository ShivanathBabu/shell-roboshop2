#!/bin/bash
set -euo pipefail

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0f591864e3e9914fe"
ZONE_ID="Z01951312K8AD4CADLS9"
DOMAIN_NAME="daws84s.site"

for instance in "$@"; do
    echo "Launching instance: $instance"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    if [ -z "$INSTANCE_ID" ]; then
        echo "Failed to launch instance: $instance"
        continue
    fi

    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance IP address: $IP"

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
            \"Comment\": \"Creating or Updating a record set for $instance\",
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 300,
                    \"ResourceRecords\": [{\"Value\": \"$IP\"}]
                }
            }]
        }"
done
