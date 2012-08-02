class duplicity::params inherits duplicity::defaults {
  $folder = $::fqdn
  $dest_id = $::duplicity_dest_id
  $dest_key = $::duplicity_dest_key
  $cloud = 's3'
  $bucket = undef
  $pubkey_id = undef
}
