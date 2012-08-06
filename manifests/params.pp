class duplicity::params(
  $bucket    = undef,
  $dest_id   = undef,
  $dest_key  = undef,
  $cloud     = $duplicity::defaults::cloud,
  $pubkey_id = undef,
  $hour      = $duplicity::defaults::hour,
  $minute    = $duplicity::defaults::minute
) inherits duplicity::defaults {
}
