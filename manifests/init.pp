class duplicity(
  $directories,
  $bucket = $duplicity::params::bucket,
  $dest_id = $duplicity::params::dest_id,
  $dest_key = $duplicity::params::dest_key,
  $cloud = $duplicity::params::cloud
) inherits duplicity::params {

  # Install the package
  package {
    ['duplicity', 'python-boto', 'python-rackspace-cloudfiles']: ensure => present
  }


  if !($cloud in [ 's3', 'cf' ]) {
    fail('$cloud required and at this time supports s3 for amazon s3 and cf for Rackspace cloud files')
  }

  if !$bucket {
    fail('You need to define a container/bucket name!')
  }
  if (!$dest_id or !$dest_key) {
    fail("You need to set all of your key variables: dest_id, dest_key")
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
