require 'spec_helper'

describe 'duplicity::params', :type => :class do

  job_spool = '/path/to/jobs'

  let(:params) {
    {
      :job_spool => job_spool,
    }
  }

  it "should compile" do
    be true
  end

  it "should create the job spool directory #{job_spool} before adding any jobs to it" do
    should create_file(job_spool).with(
      'ensure' => 'directory',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0755'
    )
  end
end
