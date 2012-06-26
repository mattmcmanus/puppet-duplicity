class duplicity::params {
  $bucket = $::fqdn
  $dest_id = $::duplicity_dest_id
  $dest_key = $::duplicity_dest_key
  $cloud = 's3'
}
