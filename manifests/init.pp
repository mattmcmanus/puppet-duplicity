define duplicity(
  $directories,
  $bucket = 'undef',
  $dest_id = 'undef',
  $dest_key = 'undef',
  $folder = 'undef',
  $cloud = 'undef',
  $pubkey_id = 'undef',
  $hour = 'undef',
  $minute = 'undef'
) {

  include duplicity::params

  case $bucket {
    'undef': { $_bucket = $duplicity::params::bucket }
    default: { $_bucket = $bucket }
  }

  case $dest_id {
    'undef': { $_dest_id = $duplicity::params::dest_id }
    default: { $_dest_id = $dest_id }
  }

  case $dest_key {
    'undef': { $_dest_key = $duplicity::params::dest_key }
    default: { $_dest_key = $dest_key }
  }

  case $folder {
    'undef': { $_folder = $duplicity::params::folder }
    default: { $_folder = $folder }
  }

  case $cloud {
    'undef': { $_cloud = $duplicity::params::cloud }
    default: { $_cloud = $cloud }
  }

  case $pubkey_id {
    'undef': { $_pubkey_id = $duplicity::params::pubkey_id }
    default: { $_pubkey_id = $pubkey_id }
  }

  case $hour {
    'undef': { $_hour = $duplicity::params::hour }
    default: { $_hour = $hour }
  }

  case $minute {
    'undef': { $_minute = $duplicity::params::minute }
    default: { $_minute = $minute }
  }

  # Install the packages
  package {
    ['duplicity', 'python-boto', 'gnupg']: ensure => present
  }


  if !($_cloud in [ 's3', 'cf' ]) {
    fail('$cloud required and at this time supports s3 for amazon s3 and cf for Rackspace cloud files')
  }

  if !$_bucket {
    fail('You need to define a container/bucket name!')
  }
  if (!$_dest_id or !$_dest_key) {
    fail("You need to set all of your key variables: dest_id, dest_key")
  }

  cron { $name :
    environment => ["AWS_ACCESS_KEY_ID='$_dest_id'", "AWS_SECRET_ACCESS_KEY='$_dest_key'"],
    command => template("duplicity/file-backup.sh.erb"),
    user => 'root',
    minute => $_minute,
    hour => $_hour,
  }

  if $_pubkey_id {
    exec { 'duplicity-pgp':
      command => "gpg --keyserver subkeys.pgp.net --recv-keys $_pubkey_id",
      path    => "/usr/bin:/usr/sbin:/bin",
      unless  => "gpg --list-key $_pubkey_id"
    }
  }
}
