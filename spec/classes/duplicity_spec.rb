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
      :directories    => [ '/etc/' ],
      :dest_id  => 'some_id',
      :dest_key => 'some_key'
    }
  }

  it { should contain_package('duplicity') }

  it {
    should contain_file('file-backup.sh') \
      .with_path('/root/scripts/file-backup.sh') \
      .with_content(/duplicity remove-older-than 6M --include \'\/etc\/\' --exclude \'\*\*\' \/ s3\+https:\/\/#{Regexp.escape(fqdn)}/)
  }
end
