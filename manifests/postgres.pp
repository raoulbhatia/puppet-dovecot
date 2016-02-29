# 10-auth.conf
# dovecot-sql.conf.ext
class dovecot::postgres (
  $dbname          = 'mails',
  $dbpassword      = 'admin',
  $dbusername      = 'pass',
  $dbhost          = 'localhost',
  $dbport          = 5432,
  $dbdriver        = 'pgsql',
  $mailstorepath   = '/srv/vmail/',
  $pass_scheme     = 'CRYPT',
  $sqlconftemplate = 'dovecot/dovecot-sql.conf.ext',
  $user_query      = "SELECT '<%= @mailstorepath %>'||SUBSTRING(email from (position('@' in email)+1) for (char_length(email)-position('@' in email)+1)) || '/' || SUBSTRING(email from 0 for position('@' in email)) AS home, '*:bytes='||quota AS quota_rule FROM users WHERE email = '%u'",
  $pass_query      = "SELECT '<%= @mailstorepath %>'||SUBSTRING(email from (position('@' in email)+1) for (char_length(email)-position('@' in email)+1)) || '/' || SUBSTRING(email from 0 for position('@' in email)) AS userdb_home, email AS user, password, '*:bytes='||quota AS userdb_quota_rule FROM users WHERE email = '%u'"
) {
  file { "/etc/dovecot/dovecot-sql.conf.ext":
    ensure  => present,
    content => template($sqlconftemplate),
    mode    => '0600',
    owner   => root,
    group   => dovecot,
    require => Package['dovecot-pgsql'],
    before  => Exec['dovecot'],
    notify  => Service['dovecot'],
  }

  package {'dovecot-pgsql':
    ensure => installed,
    before => Exec['dovecot'],
    notify => Service['dovecot']
  }

  dovecot::config::dovecotcfmulti { 'sqlauth':
    config_file => 'conf.d/10-auth.conf',
    changes     => [
      "set include 'auth-sql.conf.ext'",
      "rm  include[ . = 'auth-system.conf.ext']",
    ],
    require     => File["/etc/dovecot/dovecot-sql.conf.ext"]
  }
}
