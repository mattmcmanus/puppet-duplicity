# Puppet Duplicity

Install duplicity and quickly setup complete system backup to amazon s3

## Variables

1. $aws_access_key_id
2. $aws_secret_access_key
3. $passphrase
    Duplicity backup passwords
4. $s3_bucket
    The Amazon s3 bucket name
5. $enable_backup
    Automatically install backup script and cronjob that runs every night at 1am

## Setup

1. Install the module
2. Set your variables
3. Include duplicity

Example:
    
    $aws_access_key_id=xxx
    $aws_secret_access_key=xxx
    $passphrase=xxx
    $s3_bucket="amazon_bucket_name"
    $enable_backup=true
  
    include duplicity

## Tested

This has been verified to work on Ubuntu 11.04