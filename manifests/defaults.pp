class duplicity::defaults {
  $folder = $::fqdn
  $cloud = 's3'
  $hour = 0
  $minute = 0
  $full_if_older_than = '30D'
  $remove_older_than = '6M'
}
