class duplicity::params {
  $bucket = $::fqdn # XXX need to find some good default, or none
  $folder = $::fqdn
  $dest_id = $::duplicity_dest_id
  $dest_key = $::duplicity_dest_key
  $cloud = 's3'
}
