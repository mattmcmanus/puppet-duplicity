require 'spec_helper'

describe 'duplicity' do

  fqdn = 'somehost.domaindomain.org'

  let(:facts) {
    {
      :fqdn => fqdn
    }
  }

  let(:params) {
    {
      :bucket       => 'somebucket',
      :directories    => [ '/etc/' ],
      :dest_id  => 'some_id',
      :dest_key => 'some_key'
    }
  }

  it { should contain_package('duplicity') }

  it {
    should contain_file('file-backup.sh') \
      .with_path('/usr/local/bin/duplicity_backup_puppet.sh') \
      .with_content(/duplicity --full-if-older-than 30D --s3-use-new-style --no-encryption --include \'\/etc\/\' --exclude \'\*\*\' \/ s3\+http:\/\/somebucket\/#{Regexp.escape(fqdn)}/)
  }
end
