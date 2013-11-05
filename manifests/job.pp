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
  $ssh_id = undef,
  $pubkey_id = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $remove_older_than = undef,
  $archive_dir = false,
  $rrs                   = false,
  $allow_source_mismatch = false,
) {

  include duplicity::params
  include duplicity::packages

  if ($target and ($cloud or $bucket or $folder)) {
    fail('The target parameter and the combination of the cloud, bucket and folder parameters are mutually exclusive. Please use the target parameter, the others are deprecated.')
  }

  $rtarget = $target ? {
    undef => $duplicity::params::target,
    default => $target
  }

  if (!$rtarget) {
    # target takes precedence over cloud parameters
    $rbucket = $bucket ? {
      undef => $duplicity::params::bucket,
      default => $bucket
    }

    $rfolder = $folder ? {
      undef => $duplicity::params::folder,
      default => $folder
    }

    $rcloud = $cloud ? {
      undef => $duplicity::params::cloud,
      default => $cloud
    }
  }

  $rdest_id = $dest_id ? {
    undef => $duplicity::params::dest_id,
    default => $dest_id
  }

  $rdest_key = $dest_key ? {
    undef => $duplicity::params::dest_key,
    default => $dest_key
  }

  $rssh_id = $ssh_id ? {
    undef => $duplicity::params::ssh_id,
    default => $ssh_id
  }

  $rpubkey_id = $pubkey_id ? {
    undef => $duplicity::params::pubkey_id,
    default => $pubkey_id
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

  $rssh_options = $rssh_id ? {
    undef => ' ',
    default => " --ssh-options -oIdentityFile='$rssh_id' "
  }

  # convert the old cloud, bucket and target parameters into the new target parameter
  if (! $rtarget) {

    warning('The cloud, bucket and folder parameters are deprecated. Please change your manifests to use the more general target parameter.')

    $rurl = $rcloud ? {
      'cf' => "cf+http://$rbucket",
      's3' => "s3+http://$rbucket/$rfolder/$name/",
      'file' => "file://$rbucket"
    }
  } else {
    $rurl = $rtarget
  }

  case $ensure {
    'present' : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }

      if !$rurl {
        fail('You need to define a target URL!')
      }

    }

    'absent' : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }

  $rscheme = regsubst($rurl, '^([^:]*):.*$', '\1')

  $renvironment = $rscheme ? {
    'cf+http' => ["CLOUDFILES_USERNAME='$rdest_id'", "CLOUDFILES_APIKEY='$rdest_key'"],
    /s3|s3\+http/ => ["AWS_ACCESS_KEY_ID='$rdest_id'", "AWS_SECRET_ACCESS_KEY='$rdest_key'"],
    default => [],
  }

  $rremove_older_than_command = $rremove_older_than ? {
    undef => '',
    default => " && duplicity remove-older-than $rremove_older_than --s3-use-new-style ${rencryption}${rssh_options}--force $rurl"
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
