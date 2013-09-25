define duplicity::job(
  $ensure = 'present',
  $directory = $name,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $pubkey_id = undef,
  $hour = undef,
  $minute = undef,
  $full_if_older_than = undef,
  $remove_older_than = undef,
  $pre_command = undef,
  $default_exit_code = undef,
	$spoolfile,
) {

  include duplicity::params
  include duplicity::packages

  $_pre_command = $pre_command ? {
    undef => '',
    default => "$pre_command && "
  }

  $_encryption = $pubkey_id ? {
    undef => '--no-encryption',
    default => "--encrypt-key $pubkey_id"
  }

  $_remove_older_than = $remove_older_than ? {
    undef   => $duplicity::params::remove_older_than,
    default => $remove_older_than,
  }

  if !($cloud in [ 's3', 'cf' ]) {
    fail('$cloud required and at this time supports s3 for amazon s3 and cf for Rackspace cloud files')
  }

  case $ensure {
    'present' : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }

      if !$bucket {
        fail('You need to define a container/bucket name!')
      }

      if (!$dest_id or !$dest_key) {
        fail('You need to set all of your key variables: dest_id, dest_key')
      }

    }

    'absent' : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }

  $_cfhash = { 'CLOUDFILES_USERNAME' => $dest_id, 'CLOUDFILES_APIKEY'     => $dest_key,}
  $_awshash = { 'AWS_ACCESS_KEY_ID'  => $dest_id, 'AWS_SECRET_ACCESS_KEY' => $dest_key,}

  $_environment = $cloud ? {
    'cf' => $_cfhash,
    's3' => $_awshash,
  }

  $_target_url = $cloud ? {
    'cf' => "'cf+http://${bucket}'",
    's3' => "'s3+http://${bucket}/${folder}/${name}/'"
  }

  $_remove_older_than_command = $remove_older_than ? {
    undef => '',
    default => " && duplicity remove-older-than ${remove_older_than} --s3-use-new-style ${_encryption} --force ${_target_url}"
  }

  file { $spoolfile:
    ensure  => $ensure,
    content => template('duplicity/file-backup.sh.erb'),
    owner   => 'root',
    mode    => '0700',
  }

  if $_pubkey_id {
    @duplicity::gpg{ $_pubkey_id: }
  }
}
