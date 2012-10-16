Puppet Duplicity
================

Install duplicity and quickly setup backup to amazon s3

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
      pre_command => 'mysqldump my_database > /my_backupdir/my_database.sql',
      directory => '/my_backupdir',
      bucket => 'test-backup',
      dest_id => 'someid',
      dest_key => 'somekey',
    }

Removing Old Backups
--------------------

To remove old backups after a successful backup, you can use the ```remove_older_than``` parameter.
For example: Remove backups older than 6 months:

    duplicity { 'my_backup':
      directory => '/root/db-backup',
      bucket => 'test-backup',
      dest_id => 'someid',
      dest_key => 'somekey',
      remove_older_than => '6M',
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
        dest_key => 'somekey',
        remove_older_than => '6M',
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
