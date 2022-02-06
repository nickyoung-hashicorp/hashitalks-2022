#!/usr/bin/env bash

source ~/.bashrc
sudo vault operator migrate -config migrate.hcl
sudo chown -R vault:vault /opt/vault/
sudo systemctl start vault
sudo systemctl status vault