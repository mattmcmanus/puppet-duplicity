class duplicity {
  # Install the package
  package {   
    ['duplicity', 'python-boto', 'python-rackspace-cloudfiles']: ensure => present
  }
  
  if $enable_backup {
    
    if $backup_dest in [ 's3', 'cf' ] {
      $backup_dest_real = $backup_dest
    } else {
      fail('$backup_dest required and at this time supports s3 for amazon s3 and cf for Rackspace cloud files')
    }
    
    if !$dest_container {
      fail('You need to define a container/bucket name in $container!')
    }
    
    if (!$dest_id or !$dest_key or !$passphrase) {
      fail("You need to set all of your key variables: aws_access_key_id, aws_secret_access_key and passphrase")
    }
    
    file {
      "file-backup.sh":
        path => "/root/scripts/file-backup.sh",
        content  => template("duplicity/file-backup.sh.erb"),
        require => [File["root/scripts"], Package["duplicity"]],
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