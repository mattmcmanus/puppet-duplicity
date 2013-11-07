class duplicity::params(
  $target                = undef,
  $bucket                = undef,
  $dest_id               = undef,
  $dest_key              = undef,
  $cloud                 = $duplicity::defaults::cloud,
  $ssh_id                = undef,
  $pubkey_id             = undef,
  $hour                  = $duplicity::defaults::hour,
  $minute                = $duplicity::defaults::minute,
  $full_if_older_than    = $duplicity::defaults::full_if_older_than,
  $remove_older_than     = undef,
  $job_spool = $duplicity::defaults::job_spool
) inherits duplicity::defaults {

  file { $job_spool :
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => 0755,
  }

  File[$job_spool] -> Duplicity::Job <| |>
}
