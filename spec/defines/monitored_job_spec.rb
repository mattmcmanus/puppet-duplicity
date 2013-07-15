require 'spec_helper'

describe 'duplicity::monitored_job' do

  let (:params) { {
    :bucket            => 'somebucket',
    :directory         => '/root/mysqldump',
    :dest_id           => 'some_id',
    :dest_key          => 'some_key',
    :minute            => 0,
    :hour              => 0,
    :execution_timeout => '24h',
    :cloud             => 's3',
  } }

  fqdn = 'somehost.domaindomain.org'

  let(:facts) {
    {
      :fqdn => fqdn,
    }
  }

  let(:title) { 'some_backup_name' }

  let(:spoolfile) { "/var/spool/duplicity/#{title}.sh" }

  it 'should monitor the duplicity backup job with periodic noise' do
    should contain_periodicnoise__monitored_cron(title).with({
      :command => spoolfile,
      :user    => 'root',
      :minute  => 0,
      :hour    => 0,
      :execution_timeout => '24h',
    })
  end


  context "cloud files environment" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :execution_timeout => '24h',
        :cloud    => 'cf'
      }
    }

    it "adds a cronjob at midnight by default" do

      should contain_periodicnoise__monitored_cron(title) \
        .with_command(spoolfile)

      should contain_cron(title) \
        .with_environment([ 'CLOUDFILES_USERNAME=\'some_id\'', 'CLOUDFILES_APIKEY=\'some_key\'' ])

      should contain_file(spoolfile) \
        .with_content(/^duplicity --full-if-older-than 30D --s3-use-new-style --no-encryption --include '\/etc\/' --exclude '\*\*' \/ 'cf\+http:\/\/somebucket'$/)
    end
  end

  context "without encryption" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :execution_timeout => '24h',
      }
    }

    it "adds a cronjob at midnight by default" do
      should contain_periodicnoise__monitored_cron(title) \
        .with_command(spoolfile)

      should contain_cron(title) \
        .with_environment([ 'AWS_ACCESS_KEY_ID=\'some_id\'', 'AWS_SECRET_ACCESS_KEY=\'some_key\'' ])

      should contain_file(spoolfile) \
        .with_content(/^duplicity --full-if-older-than 30D --s3-use-new-style --no-encryption --include '\/etc\/' --exclude '\*\*' \/ 's3\+http:\/\/somebucket\/#{fqdn}\/some_backup_name\/'$/)
    end
  end

  context "with defined force full-backup" do

    let(:params) {
      {
        :bucket             => 'somebucket',
        :directory          => '/etc/',
        :dest_id            => 'some_id',
        :execution_timeout => '24h',
        :dest_key           => 'some_key',
        :full_if_older_than => '5D',
      }
    }

    it "should be able to handle a specified backup time" do
      should contain_periodicnoise__monitored_cron(title) \
        .with_command(spoolfile)

      should contain_file(spoolfile) \
        .with_content(/--full-if-older-than 5D/)
    end
  end

  context "with defined backup time" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id      => 'some_id',
        :execution_timeout => '24h',
        :dest_key     => 'some_key',
        :hour         => 5,
        :minute       => 23
      }
    }

    it "should be able to handle a specified backup time" do
       should contain_periodicnoise__monitored_cron(title) \
         .with_minute(23) \
         .with_hour(5)
    end
  end

  context "with defined remove-older-than" do

    let(:params) {
      {
        :bucket             => 'somebucket',
        :execution_timeout => '24h',
        :directory          => '/etc/',
        :dest_id            => 'some_id',
        :dest_key           => 'some_key',
        :remove_older_than => '7D',
      }
    }

    it "should be able to handle a specified remove-older-than time" do
      should contain_periodicnoise__monitored_cron(title) \
        .with_command(spoolfile)

      should contain_file(spoolfile) \
        .with_content(/remove-older-than 7D.* --no-encryption --force.*/)
    end
  end

  context 'duplicity with pubkey encryption' do

    some_pubkey_id = '15ABDA79'
    fqdn = 'somehost.domaindomain.org'

    let(:params) {
      {
        :bucket       => 'somebucket',
        :execution_timeout => '24h',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :pubkey_id   => some_pubkey_id
      }
    }

    it "should use pubkey encryption if keyid is provided" do
      should contain_periodicnoise__monitored_cron(title) \
        .with_command(spoolfile)

      should contain_file(spoolfile) \
        .with_content(/--encrypt-key #{some_pubkey_id}/)
    end

    it "should download and import the specified pubkey" do
      should contain_exec('duplicity-pgp') \
        .with_command("gpg --keyserver subkeys.pgp.net --recv-keys #{some_pubkey_id}") \
        .with_path("/usr/bin:/usr/sbin:/bin") \
        .with_unless("gpg --list-key #{some_pubkey_id}")
    end
  end

  context 'with default bucket and bucket as param' do
    let(:params) {
      {
        :directory    => '/etc/',
        :execution_timeout => '24h',
        :bucket       => 'from_param'
      }
    }

    let (:pre_condition) {
      "class { 'duplicity::params' :
        bucket => 'default',
        dest_id => 'some_id',
        dest_key => 'some_key'
      }"
    }

    it "should override default bucket with param" do
      should contain_periodicnoise__monitored_cron(title) \
        .with_command(spoolfile)

      should contain_file(spoolfile) \
        .with_content(/from_param/)
    end
  end

  context 'duplicity defaults' do
    let(:params) {
      {
        :execution_timeout => '24h',
        :directory    => '/etc/',
      }
    }

    let (:pre_condition) {
      "class { 'duplicity::params' :
        bucket => 'another_bucket',
        dest_id => 'some_id',
        dest_key => 'some_key'
      }"
    }

    it "contains package" do
      should contain_package('duplicity')
      should contain_package('gnupg')
    end

    it "should be able to set a global cloud key pair config" do
      should contain_periodicnoise__monitored_cron(title) \
        .with_command(spoolfile)

      should contain_cron(title) \
        .with_environment([ 'AWS_ACCESS_KEY_ID=\'some_id\'', 'AWS_SECRET_ACCESS_KEY=\'some_key\'' ])

      should contain_file(spoolfile) \
        .with_content(/another_bucket/)

    end

    it "should be able to set a global pubkey id" do
    end
  end

  context "with pre_command" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/root/mysqldump',
        :dest_id      => 'some_id',
        :execution_timeout => '24h',
        :dest_key     => 'some_key',
        :pre_command  => 'mysqldump database',
      }
    }

    it "should prepend pre_command to cronjob" do
      should contain_periodicnoise__monitored_cron(title) \
        .with_command(spoolfile)

      should contain_file(spoolfile) \
        .with_content(/^mysqldump database && /)
    end
  end

  context 'with ensure => absent' do

    let(:params) {
      {
        :execution_timeout => '24h',
        :ensure       => 'absent'
      }
    }

    it 'should remove the cron and the job file' do
      should contain_periodicnoise__monitored_cron(title) \
        .with_ensure('absent')
      should contain_file(spoolfile) \
        .with_ensure('absent')
    end
  end

end
