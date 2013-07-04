define duplicity::monitored_job(
  $bucket,
  $directory,
  $dest_id,
  $dest_key,
  $execution_timeout,
  $minute,
  $hour,
)
{
  include duplicity::params

  $_hour = $hour ? {
    undef => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef => $duplicity::params::minute,
    default => $minute
  }

  periodicnoise::monitored_cron { $title :
    command => "",
    user => 'root',
    minute => $_minute,
    hour => $_hour,
    execution_timeout => $execution_timeout

  }

}
