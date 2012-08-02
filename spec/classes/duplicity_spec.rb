require 'spec_helper'

describe 'duplicity' do

  fqdn = 'somehost.domaindomain.org'

  let(:facts) {
    {
      :fqdn => fqdn
    }
  }

  context "no encryption" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directories    => [ '/etc/' ],
        :dest_id  => 'some_id',
        :dest_key => 'some_key'
      }
    }

    it "contains package" do
      should contain_package('duplicity')
      should contain_package('gnupg')
    end

    it "generates a file backup script to /usr/local/bin" do
      should contain_file('file-backup.sh') \
        .with_path('/usr/local/bin/duplicity_backup_puppet.sh') \
        .with_content(/duplicity --full-if-older-than 30D --s3-use-new-style --no-encryption --include \'\/etc\/\' --exclude \'\*\*\' \/ s3\+http:\/\/somebucket\/#{Regexp.escape(fqdn)}/)
    end

    it "should make a full backup every X days" do

    end
  end

  context "more than one directory to backup" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directories    => [ '/etc/', '/some_other_dir/' ],
        :dest_id  => 'some_id',
        :dest_key => 'some_key'
      }
    }

    it "should be able to backup more than one directory" do
      should contain_file('file-backup.sh') \
        .with_path('/usr/local/bin/duplicity_backup_puppet.sh') \
        .with_content(/duplicity --full-if-older-than 30D --s3-use-new-style --no-encryption --include \'\/etc\/\' --include \'\/some_other_dir\/\' --exclude \'\*\*\' \/ s3\+http:\/\/somebucket\/#{Regexp.escape(fqdn)}/)
    end
  end

  context 'duplicity with pubkey encryption' do

    some_pubkey_id = '15ABDA79'
    fqdn = 'somehost.domaindomain.org'

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directories    => [ '/etc/' ],
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :pubkey_id   => some_pubkey_id
      }
    }

    it "should use pubkey encryption if keyid is provided" do
      should contain_file('file-backup.sh') \
        .with_content(/duplicity --full-if-older-than 30D --s3-use-new-style --encrypt-key #{some_pubkey_id} --include \'\/etc\/\' --exclude \'\*\*\' \/ s3\+http:\/\/somebucket\/#{Regexp.escape(fqdn)}/)
    end

    it "should download and import the specified pubkey" do
      should contain_exec('duplicity-pgp') \
        .with_command("gpg --keyserver subkeys.pgp.net --recv-keys #{some_pubkey_id}") \
        .with_path("/usr/bin:/usr/sbin:/bin") \
        .with_unless("gpg --list-key #{some_pubkey_id}")
    end
  end

  context 'duplicity defaults' do

    it "should be able to set a global cloud key pair config" do
    end

    it "should be able to set a global pubkey id" do
    end
  end
end
