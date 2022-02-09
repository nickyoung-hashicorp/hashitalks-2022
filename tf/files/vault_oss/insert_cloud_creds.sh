#!/usr/bin/env bash

cat access_key.txt >> ~/.bashrc
cat secret_key.txt >> ~/.bashrc
echo 'export AWS_DEFAULT_REGION=us-west-2' >> ~/.bashrc