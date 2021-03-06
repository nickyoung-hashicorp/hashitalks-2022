Start Demo
==========

## Here, I have 3 distinct terminal windows.  Starting at the bottom, I have an SSH session to my Vault OSS environment shown by this dark grey window, in the top-left I have my session to the Vault Enterprise environment in the green window, and in the top-right I have my session to the Vault Enterprise with HSM environment in the orange colored window.  This should hopefully help you follow along mentally with the diagrams I showed earlier.

## I'm going to start on the bottom terminal window with my open source Vault, which contains all my secrets, auth methods, policies, and so on.

## First, I'll run `vault status`
```
vault status
```
## This shows that Vault is using Shamir as its seal type, initialized and unsealed, and using DynamoDB as its storage type.

## Next, I'll list out some of the files that I'll be using throughout this demo.
```
ls -l
```

## First, the ciphertext file is something I generated when I encrypted some plaintext using the Transit secret engine.  The Lease ID text file just captures a lease generated by Vault when I created a MySQL credential using the database secrets engine.  This output text file was created with some outputs from the Terraform run to help me automate some of this demo.  The test vault script is something I'll show in a minute.  And the Vault init file has 1 key share and the root token that were generated with this Vault when I first initialized it  The reason for the files was just to help automate this demo.


## So first, let's checkout the test script that goes through testing the secret engines, and will be a form a validation as I progress through the migration.
```
vim test_vault.sh
```
## This is largely a list of vault and colored echo commands that I'm using to automate the validation steps that tell me I'm getting the responses I want out of Vault.  The sleep commands are just so you can all view what's happening without the terminal printing too fast.  We also test the userpass auth method and an associated policy to ensure that policies are being transferred in the migration process as well.

## So now, we'll go ahead and run that test script.
```
./test_vault.sh
```
## And all of that looks as we'd expect!

## Next, we're now going to stop our Vault service.  This way, we know that there's no additional data or leases being created in Vault.
```
sudo systemctl stop vault
```

## The next thing we'll want to do is take a backup of our storage backend.  This process will look different depending on your backend, but because I'm using Vault for this demo, I'll follow the backup process as outlined in AWS' documentation.

## In this command, I'm both creating a backup, and storing the ARN as an environment variable.
```
BACKUP_ARN=$(aws dynamodb create-backup \
    --table-name vault-backend \
    --backup-name hashitalks-dynamo-backup | jq -r '.BackupDetails.BackupArn')
```
## Here, I'm using jq as a tool to filter JSON and just pull the ARN that I need.

## With that environment variable, I want to check the tatus of the backup.
```
aws dynamodb describe-backup \
    --backup-arn $BACKUP_ARN | jq '.BackupDescription.BackupDetails.BackupStatus'
```
## And here I see that the status is AVAILABLE which tells me the backup was successful.

## Next, I'll close the grey window because we won't need our open source Vault for the remainder of this talk.  Now we're going to focus on the environment with Vault Enterprise, or this red window here.

## Just a reminder about this Vault Enterprise node, it has been setup so we have the Vault service loaded, but has not been started or initialized because this next step will Vault for us then migrate the data before we start the Vault service.

## So first, let's take a look at the HCL file we'll need as part of this migration step.
```
vim migrate.hcl
```
## As I showed in the deck, this Vault Enterprise node has access to the DynamoDB table with the help of Instance Profiles, as well as it's local file system, which is how Raft works to store Vault data.

## We're going to check out the migrate data script here
```
vim migrate_data.sh
```
## and notice 4 distinct commands.  First, we're going to run that vault operator migrate command, passing in the HCL file I showed earlier.  Then we're going to change ownership for the Vault service to access this directory.  Then we're going to start the Vault service and finally check the status.

## So we'll run the migrate data script here.
```
./migrate_data.sh
```
## and with that completed, notice a couple key things.  Namely that we are running the Vault Enterprise binary and using Raft as the "storage type".

## Next, as we have to do whenever the Vault service first comes up or restarts, we need to unseal Vault Enterprise and we're going to use the original unseal keys that we used for our open source Vault.
```
vim unseal_vault_ent.sh
```
## Not a whole lot of magic here.  I basically saved my unseal and root token to a file and I'm passing in that single key share to unseal Vault, then sleeping for a few seconds while the node elects itself as the leader, then checking the status again.

## So let's run that
```
./unseal_vault_ent.sh
```
## And now we see that we're on Vault Enterprise!

## As much as I trust the migration tool, it's important to validate.  so I'm going to run that same test script we used earlier on the open source Vault to ensure I'm getting the proper responses. I use a different name, but the tests are the same.
```
test_vault_ent.sh
```
## Great!  So we made it this far. With testing complete, we'll now setup DR Replication.  Here you'll notice me jump between the ENT and the HSM terminal sessions, so I'll do my best to call it out so viewers can follow along.

## First we're going to login with our root token
```
vault login $(cat vault_init.json | jq -r '.root_token')
```

## Then we're going to enable this Vault Enterprise cluster as the DR Primary
```
vault write -f /sys/replication/dr/primary/enable
```

## From there, we have to generate a DR token, which we'll save to a text file.
```
vault write -format=json /sys/replication/dr/primary/secondary-token id="vault-enterprise-hsm" | jq -r '.wrap_info .token' > primary_dr_token.txt
```

## Then, we're going to copy the DR Token to the HSM-integrated Vault
```
scp -i privateKey.pem primary_dr_token.txt ubuntu@$(cat output.txt | jq -r '.vault_hsm_ip.value'):~
```

## And now we'll jump over to the `HSM` terminal session

## First, we'll run Vault status to check it's current state
```
vault status
```
## Here we see that there's a `Recovery Seal Type` which is shamir, because now we're using the CloudHSM as our auto-unseal mechanism.  We also see the version is using 1.9.3 Enterprise with HSM functionality, and Raft as it's storage type.

## We'll take a look at the Vault server configuration here
```
sudo vim /etc/vault.d/vault.hcl
```
## Notice the `Seal PKCS11` stanza at the bottom here

## At this point, we're going to enable the Vault with HSM environment as the DR Secondary Cluster, using that token that we saved as a text file earlier and just copied over.
```
vault write /sys/replication/dr/secondary/enable token=$(cat primary_dr_token.txt)
```

## Then, we're going to check the replication state, Looking for `"stream-wals"` which is what we would expect from the DR Secondary
```
vault read -format=json sys/replication/status | jq '.data.dr.state'
```

## Jumping back to the `ENT` session...

## We're going to check the replication state, looking for `"running"` which is what we want for the DR Primary
```
vault read -format=json sys/replication/status | jq '.data.dr.state'
```

## To ensure that replication is functioning, we're going to write some additional key-value data so we can test for this towards the end of the demo.
```
vault kv put kv/hashitalks-secret message="HashiTalks Demo - Complete!"
vault kv get kv/hashitalks-secret
```

## Just double checking here, we're checking the replication state again, Looking for `"running"`
```
vault read -format=json sys/replication/status | jq '.data.dr.state'
```

## Now back over to the `HSM` session...

## We're checking the replication state again, Looking for `"stream-wals"`
```
vault read -format=json sys/replication/status | jq '.data.dr.state'
```

## Alright, so at this point, we have replication setup and wrote some additional KV data which we'll test for at the end.

## At this point, we're going to go through a FAILOVER process.  For this, I'll be leverage a lot of environment variables and embedding them within commands so help show the steps, but also demonstrate the possibilities of automating or scripting this procedure.

## First, we're going to generate a One-Time Password and save that as the DR_OTP variable
```
DR_OTP=$(vault operator generate-root -dr-token -generate-otp)
```

## Then pass that into the NONCE variable to initialize generating the DR Operation Token
```
NONCE=$(vault operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')
```

## At this point, we're going to validate the DR Process has started, looking for `"started": true`
```
curl -s http://127.0.0.1:8200/v1/sys/replication/dr/secondary/generate-operation-token/attempt | jq
```

## Next, we're going to save our single unseal key as the PRIMARY_UNSEAL_KEY variable
```
PRIMARY_UNSEAL_KEY=$(cat vault_init.json | jq -r '.unseal_keys_b64[0]')
```

## We will use that along with the NONCE value and save this output as the ENCODED_TOKEN variable
```
ENCODED_TOKEN=$(vault operator generate-root -dr-token -nonce=$NONCE $PRIMARY_UNSEAL_KEY | grep -i encoded | awk '{print $3}' )
```

## And finally, we'll pass both the ENCODED_TOKEN and DR_OTP values and save that as a DR_OPERATION_TOKEN variable.
```
DR_OPERATION_TOKEN=$(vault operator generate-root -dr-token -otp=$DR_OTP -decode=$ENCODED_TOKEN)
```

## At this point, we are one command away from promoting the DR Secondary (or the Vault with HSM) to become to new primary, active Vault cluster.

## Before doing that, we'll navigate to the `ENT` session.

## And just double check that this cluster's mode is `"primary"`
```
vault read -format=json sys/replication/status | jq '.data.dr'
```

## Now we will disable replication on this cluster
```
vault write -f /sys/replication/dr/primary/disable
```

## And check again, where we should see the cluster's mode is now `"disabled"`
```
vault read -format=json sys/replication/status | jq '.data.dr'
```

## With the DR primary now disabled, we'll jump back to the `HSM` tab.

## We'll validate that replication is now broken, looking for `"connection_status": "disconnected"`
```
vault read -format=json sys/replication/status | jq '.data.dr.primaries'
```

## Now we'll promote the Vault with HSM from Secondary to become the new primary, and pass in that DR_OPERATION_TOKEN that we saved earlier
```
vault write -f /sys/replication/dr/secondary/promote dr_operation_token=${DR_OPERATION_TOKEN}
```

## Checking the replication status...
```
vault read -format=json sys/replication/status | jq '.data.dr'
```
## it's good to see that it's now `"primary"`

## Finally, we'll login using the original Root Token that we've carried over from our open source Vault.
```
vault login $(cat vault_init.json | jq -r '.root_token')
```

## And the final step is walking through those validation tests, which is just like the tests I've shown throughout the demo, except that I add an additional `kv get` to see if that key-value I added during replication came over to this Vault HSM cluster.
```
./test_vault_hsm.sh
```
## This looks good and we can see with that final command, this concludes the demo!  We'll jump back to the slides and close out.