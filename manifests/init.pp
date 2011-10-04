class duplicity {
  # Install the package
  package {   
    ['duplicity', 'python-boto']: ensure => present
  }
  
  if $enable_backup {
    if !$s3_bucket {
      fail("You need to define a bucket name!")
    }
    
    if (!$aws_access_key_id and !$aws_secret_access_key and !$passphrase) {
      fail("You need to set all of your key variables: aws_access_key_id, aws_secret_access_key and passphrase")
    }
    
    file {
      "file-backup.sh":
        path => "/root/scripts/file-backup.sh",
        content  => template("duplicity/file-backup.sh.erb"),
        require => File["root/scripts"], # Defined in basenode
        owner => root, group => 0, mode => 0500,
        ensure => present;
    }
    
    cron { 'duplicity_backup_cron':
      command => "/bin/sh /root/scripts/file-backup.sh",
      user => 'root',
      minute => 0,
      hour => 1,
      require => [ File['file-backup.sh'] ],
    }
  }
}