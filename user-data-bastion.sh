#!/bin/bash
echo "${tls_private_key.asg_key.private_key_pem}" > /home/ubuntu/asg-key.pem
chown ubuntu:ubuntu /home/ubuntu/asg-key.pem
chmod 600 /home/ubuntu/asg-key.pem
