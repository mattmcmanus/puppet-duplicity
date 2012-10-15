Puppet Duplicity
================

Installs duplicity and quickly setup complete system backup to amazon s3

Currently rewriting the module:

 * puppet-rspec tests
 * duplicity with gpg pubkey
 * you may specificy the dirs (no full backup)
 * no usage of global vars anymore

Basic Usage
-----------
    node 'kellerautomat' {

      duplicity { 'a_backup':
        directory => '/home/soenke/',
        bucket => 'test-backup-soenke',
        dest_id => 'someid',
        dest_key => 'somekey'
      }
    }

Preparing Backup
----------------

To prepare files for backup, you can use the ```pre_command``` parameter.
For example: do a mysqldump before running duplicity.

      duplicity { 'my_database':
        pre_command => 'mysqldump my_database > /root/db-backup/my_database.sql'
        directory => '/root/db-backup',
        bucket => 'test-backup',
        dest_id => 'someid',
        dest_key => 'somekey'
      }

Global Parameters
-----------------

Access ID and Key, Crypt-Pubkey and bucket name will be global in most cases. To avoid copy-and-paste
you can pass the global defaults once to duplicity::params before you include the duplicity class somewhere.

Example:

    class defaults {
      class { 'duplicity::params' :
        bucket => 'test-backup-soenke',
        dest_id => 'someid',
        dest_key => 'somekey'
      }
    }

    node 'kellerautomat' {

      include defaults

      duplicity { 'blubbi' :
        directory => '/home/soenke/projects/test-puppet',
      }
    }

Crypted Backups
---------------

In order to save crypted backups this module is able to make use of pubkey encryption.
This means you specify a pubkey and restores are only possible with the correspondending
private key. This ensures no secret credentials fly around on the machines. Incremental backups
work as long as the metadata cache on the node is up to date. Duplicity will force a full backup
otherwise because it cannot decrypt anything it downloads from the bucket.

Check https://answers.launchpad.net/duplicity/+question/107216 for more information.

Restore
-------

Nobody wants backup, everybode wants restore.
