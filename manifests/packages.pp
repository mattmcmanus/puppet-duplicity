class duplicity::packages {
  # Install the packages
  package {
    ['duplicity', 'python-boto', 'gnupg']: ensure => present
  }
}
