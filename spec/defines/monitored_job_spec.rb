describe 'duplicity::monitored_job' do

  let (:title) { 'some_descriptive_name_for_duplicity_job' }

  let (:params) { {
    :bucket            => 'somebucket',
    :directory         => '/root/mysqldump',
    :dest_id           => 'some_id',
    :dest_key          => 'some_key',
    :minute            => 0,
    :hour              => 0,
    :execution_timeout => '24h',
  } }

  it 'should monitor the duplicity backup job with periodic noise' do
    should contain_periodicnoise__monitored_cron(title).with({
        :command => "",
        :user    => 'root',
        :minute  => 0,
        :hour    => 0,
    })

#    should contain_duplicity(title)
  end

end
