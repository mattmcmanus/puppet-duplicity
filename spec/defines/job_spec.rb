require 'spec_helper'

describe 'duplicity::job' do

  fqdn = 'somehost.domaindomain.org'

  let(:facts) {
    {
      :fqdn => fqdn
    }
  }

  let(:title) { 'some_backup_name' }

  let(:spoolfile) { "/var/spool/duplicity/#{title}.sh" }

  let(:params) {
    {
      :bucket    => 'somebucket',
      :directory => '/etc/',
      :dest_id   => 'some_id',
      :dest_key  => 'some_key',
      :spoolfile => spoolfile,
    }
  }

  it 'should be owned by root and only accessable by root and only root' do
    should contain_file(spoolfile) \
      .with_owner('root') \
      .with_mode('0700')
  end

  context "cloud files environment" do

    let(:params) {
      {
        :bucket    => 'somebucket',
        :directory => '/etc/',
        :dest_id   => 'some_id',
        :dest_key  => 'some_key',
        :cloud     => 'cf',
        :spoolfile => spoolfile,
      }
    }

    it "adds a spoolfile which contains the generated backup script" do
      should contain_file(spoolfile) \
        .with_content(/^CLOUDFILES_USERNAME='some_id'$/)\
        .with_content(/^CLOUDFILES_APIKEY='some_key'$/)\
        .with_content(/^duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --no-encryption --include '\/etc\/' --exclude '\*\*' \/ 'cf\+http:\/\/somebucket'$/)
    end
  end

  context "without encryption" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :spoolfile => spoolfile,
      }
    }

    it "adds spoolfile which contains the generated backup script" do
      should contain_file(spoolfile) \
        .with_content(/^AWS_ACCESS_KEY_ID='some_id'$/)\
        .with_content(/^AWS_SECRET_ACCESS_KEY='some_key'$/)\
        .with_content(/^duplicity --verbosity warning --no-print-statistics --full-if-older-than 30D --s3-use-new-style --no-encryption --include '\/etc\/' --exclude '\*\*' \/ 's3\+http:\/\/somebucket\/#{fqdn}\/some_backup_name\/'$/)
    end


    it "should make a full backup every X days" do

    end
  end

  context "with defined force full-backup" do

    let(:params) {
      {
        :bucket             => 'somebucket',
        :directory          => '/etc/',
        :dest_id            => 'some_id',
        :dest_key           => 'some_key',
        :full_if_older_than => '5D',
        :spoolfile => spoolfile,
      }
    }

    it "should do a full backup after the specified time" do
      should contain_file(spoolfile) \
        .with_content(/--full-if-older-than 5D/)
    end
  end

  context "with defined remove-older-than" do

    let(:params) {
      {
        :bucket             => 'somebucket',
        :directory          => '/etc/',
        :dest_id            => 'some_id',
        :dest_key           => 'some_key',
        :remove_older_than => '7D',
        :spoolfile => spoolfile,
      }
    }

    it "should be able to handle a specified remove-older-than time" do
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
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :pubkey_id   => some_pubkey_id,
        :spoolfile => spoolfile,
      }
    }

    it "should use pubkey encryption if keyid is provided" do
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
        :bucket       => 'from_param',
        :spoolfile => spoolfile,
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
      should contain_file(spoolfile) \
        .with_content(/from_param/)
    end
  end

  context 'duplicity defaults' do
    let(:params) {
      {
        :directory    => '/etc/',
        :spoolfile => spoolfile,
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
      should contain_file(spoolfile) \
        .with_content(/^AWS_ACCESS_KEY_ID='some_id'$/)\
        .with_content(/^AWS_SECRET_ACCESS_KEY='some_key'$/)\
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
        :dest_key     => 'some_key',
        :pre_command  => 'mysqldump database',
        :spoolfile => spoolfile,
      }
    }

    it "should prepend pre_command to cronjob" do
      should contain_file(spoolfile) \
        .with_content(/^mysqldump database && /)
    end
  end

  context 'with ensure => absent' do

    let(:params) {
      {
        :ensure       => 'absent',
        :spoolfile => spoolfile,
      }
    }

    it 'should remove the job file' do
      should contain_file(spoolfile) \
        .with_ensure('absent')
    end

  end
end
