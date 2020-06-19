#!/bin/bash

ssh -t ${PROD_USER}@${IP_ADDRESS} "cd /var/www/bird_signs; bash"
