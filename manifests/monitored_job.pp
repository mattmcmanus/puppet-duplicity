define duplicity::monitored_job(
  $ensure = 'present',
  $directory = undef,
  $target = undef,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $pubkey_id = undef,
  $hour = undef,
  $minute = undef,
  $weekday = undef,
  $month = undef,
  $monthday = undef,
  $user = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $remove_older_than = undef,
  $execution_timeout
)
{
  include duplicity::params
  include duplicity::packages

  $spoolfile = "${duplicity::params::job_spool}/${name}.sh"

  duplicity::job { $name :
    ensure => $ensure,
    spoolfile => $spoolfile,
    directory => $directory,
    target => $target,
    bucket => $bucket,
    dest_id => $dest_id,
    dest_key => $dest_key,
    folder => $folder,
    cloud => $cloud,
    pubkey_id => $pubkey_id,
    full_if_older_than => $full_if_older_than,
    pre_command => $pre_command,
    remove_older_than => $remove_older_than,
  }

  $rhour = $hour ? {
    undef => $duplicity::params::hour,
    default => $hour
  }

  $rminute = $minute ? {
    undef => $duplicity::params::minute,
    default => $minute
  }

  $rweekday = $weekday ? {
    undef => $duplicity::defaults::weekday,
    default => $weekday
  }

  $rmonth = $month ? {
    undef => $duplicity::defaults::month,
    default => $month
  }

  $rmonthday = $monthday ? {
    undef => $duplicity::defaults::monthday,
    default => $monthday
  }

  $ruser = $user ? {
    undef => $duplicity::defaults::user,
    default => $user
  }

  periodicnoise::monitored_cron { $name :
    ensure => $ensure,
    command => $spoolfile,
    user => $ruser,
    minute => $rminute,
    hour => $rhour,
    weekday => $rweekday,
    month => $rmonth,
    monthday => $rmonthday,
    execution_timeout => $execution_timeout,
  }

  File[$spoolfile]->Cron[$name]
}
