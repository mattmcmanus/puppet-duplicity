define duplicity::job(
  $ensure = 'present',
  $spoolfile,
  $directory = undef,
  $target = undef,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $pubkey_id = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $remove_older_than = undef,
) {

  include duplicity::params
  include duplicity::packages

  if ($target and ($cloud or $bucket or $folder)) {
    fail('The target parameter and the combination of the cloud, bucket and folder parameters are mutually exclusive. Please use the target parameter, the others are deprecated.')
  }

  $_target = $target ? {
    undef => $duplicity::params::target,
    default => $target
  }

  if (!$_target) {
    # target takes precedence over cloud parameters
    $_bucket = $bucket ? {
      undef => $duplicity::params::bucket,
      default => $bucket
    }

    $_folder = $folder ? {
      undef => $duplicity::params::folder,
      default => $folder
    }

    $_cloud = $cloud ? {
      undef => $duplicity::params::cloud,
      default => $cloud
    }
  }

  $_dest_id = $dest_id ? {
    undef => $duplicity::params::dest_id,
    default => $dest_id
  }

  $_dest_key = $dest_key ? {
    undef => $duplicity::params::dest_key,
    default => $dest_key
  }

  $_pubkey_id = $pubkey_id ? {
    undef => $duplicity::params::pubkey_id,
    default => $pubkey_id
  }

  $_hour = $hour ? {
    undef => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef => $duplicity::params::minute,
    default => $minute
  }

  $_full_if_older_than = $full_if_older_than ? {
    undef => $duplicity::params::full_if_older_than,
    default => $full_if_older_than
  }

  $_pre_command = $pre_command ? {
    undef => '',
    default => "$pre_command && "
  }

  $_encryption = $_pubkey_id ? {
    undef => '--no-encryption',
    default => "--encrypt-key $_pubkey_id"
  }

  $_remove_older_than = $remove_older_than ? {
    undef   => $duplicity::params::remove_older_than,
    default => $remove_older_than,
  }

  # convert the old cloud, bucket and target parameters into the new target parameter
  if (! $_target) {

    warning('The cloud, bucket and folder parameters are deprecated. Please change your manifests to use the more general target parameter.')

    $_url = $_cloud ? {
      'cf' => "cf+http://$_bucket",
      's3' => "s3+http://$_bucket/$_folder/$name/",
      'file' => "file://$_bucket"
    }
  } else {
    $_url = $_target
  }

  case $ensure {
    'present' : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }

      if !$_url {
        fail('You need to define a target URL!')
      }

    }

    'absent' : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }

  $_scheme = regsubst($_url, '^([^:]*):.*$', '\1')

  $_environment = $_scheme ? {
    'cf+http' => ["CLOUDFILES_USERNAME='$_dest_id'", "CLOUDFILES_APIKEY='$_dest_key'"],
    /s3|s3\+http/ => ["AWS_ACCESS_KEY_ID='$_dest_id'", "AWS_SECRET_ACCESS_KEY='$_dest_key'"],
    default => [],
  }

  $_remove_older_than_command = $_remove_older_than ? {
    undef => '',
    default => " && duplicity remove-older-than $_remove_older_than --s3-use-new-style $_encryption --force $_url"
  }

  file { $spoolfile:
    ensure  => $ensure,
    content => template("duplicity/file-backup.sh.erb"),
    owner   => 'root',
    mode    => 0700,
  }

  if $_pubkey_id {
    exec { 'duplicity-pgp':
      command => "gpg --keyserver subkeys.pgp.net --recv-keys $_pubkey_id",
      path    => "/usr/bin:/usr/sbin:/bin",
      unless  => "gpg --list-key $_pubkey_id"
    }
  }
}
