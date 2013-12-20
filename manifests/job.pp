define duplicity::job(
  $ensure = 'present',
  $spoolfile,
  $directory = undef,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $pubkey_id = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $remove_older_than = undef,
  $archive_dir = false,
  $rrs         = false,
) {

  include duplicity::params
  include duplicity::packages

  $rbucket = $bucket ? {
    undef => $duplicity::params::bucket,
    default => $bucket
  }

  $rdest_id = $dest_id ? {
    undef => $duplicity::params::dest_id,
    default => $dest_id
  }

  $rdest_key = $dest_key ? {
    undef => $duplicity::params::dest_key,
    default => $dest_key
  }

  $rfolder = $folder ? {
    undef => $duplicity::params::folder,
    default => $folder
  }

  $rcloud = $cloud ? {
    undef => $duplicity::params::cloud,
    default => $cloud
  }

  $rpubkey_id = $pubkey_id ? {
    undef => $duplicity::params::pubkey_id,
    default => $pubkey_id
  }

  $rhour = $hour ? {
    undef => $duplicity::params::hour,
    default => $hour
  }

  $rminute = $minute ? {
    undef => $duplicity::params::minute,
    default => $minute
  }

  $rfull_if_older_than = $full_if_older_than ? {
    undef => $duplicity::params::full_if_older_than,
    default => $full_if_older_than
  }

  $rpre_command = $pre_command ? {
    undef => '',
    default => "$pre_command && "
  }

  $rencryption = $rpubkey_id ? {
    undef => '--no-encryption',
    default => "--encrypt-key $rpubkey_id"
  }

  $rremove_older_than = $remove_older_than ? {
    undef   => $duplicity::params::remove_older_than,
    default => $remove_older_than,
  }

  $rarchive_dir = $archive_dir ? {
    false  => $duplicity::params::archive_dir,
    default => $archive_dir,
  }

  if !($rcloud in [ 's3', 'cf', 'file' ]) {
    fail('$cloud required and at this time supports s3 for amazon s3 and cf for Rackspace cloud files')
  }

  case $ensure {
    'present' : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }

      if !$rbucket {
        fail('You need to define a container/bucket name!')
      }

    }

    'absent' : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }

  $renvironment = $rcloud ? {
    'cf' => ["CLOUDFILES_USERNAME='$rdest_id'", "CLOUDFILES_APIKEY='$rdest_key'"],
    's3' => ["AWS_ACCESS_KEY_ID='$rdest_id'", "AWS_SECRET_ACCESS_KEY='$rdest_key'"],
    'file' => [],
  }

  $rtarget_url = $rcloud ? {
    'cf' => "'cf+http://$rbucket'",
    's3' => "'s3+http://$rbucket/$rfolder/$name/'",
    'file' => "'file://$rbucket'"
  }

  $rremove_older_than_command = $rremove_older_than ? {
    undef => '',
    default => " && duplicity remove-older-than $rremove_older_than --s3-use-new-style $rencryption --force $rtarget_url"
  }

  file { $spoolfile:
    ensure  => $ensure,
    content => template("duplicity/file-backup.sh.erb"),
    owner   => 'root',
    mode    => 0700,
  }

  if $rpubkey_id {
    exec { 'duplicity-pgp':
      command => "gpg --keyserver subkeys.pgp.net --recv-keys $rpubkey_id",
      path    => "/usr/bin:/usr/sbin:/bin",
      unless  => "gpg --list-key $rpubkey_id"
    }
  }
}
