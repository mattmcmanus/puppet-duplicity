class duplicity(
  $directories,
  $bucket = $duplicity::params::bucket,
  $dest_id = $duplicity::params::dest_id,
  $dest_key = $duplicity::params::dest_key,
  $folder = $duplicity::params::folder,
  $cloud = $duplicity::params::cloud,
  $pubkey_id = $duplicity::params::pubkey_id,
  $hour = $duplicity::params::hour,
  $minute = $duplicity::params::minute
) inherits duplicity::params {

  # Install the packages
  package {
    ['duplicity', 'python-boto', 'gnupg']: ensure => present
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

  $script_path = '/usr/local/bin/duplicity_backup_puppet.sh'

  file { 'file-backup.sh':
      path => $script_path,
      content  => template("duplicity/file-backup.sh.erb"),
      require => Package["duplicity"],
      owner => root,
      group => 0,
      mode => 0700,
      ensure => present;
  }

  cron { 'duplicity_backup_cron':
    command => "/bin/sh $script_path",
    user => 'root',
    minute => $minute,
    hour => $hour,
    require => File['file-backup.sh'],
  }

  if $pubkey_id {
    exec { 'duplicity-pgp':
      command => "gpg --keyserver subkeys.pgp.net --recv-keys $pubkey_id",
      path    => "/usr/bin:/usr/sbin:/bin",
      unless  => "gpg --list-key $pubkey_id"
    }
  }
}
