class MigrateWf
  attr_accessor :failed_account_ids, :req_counter, :start_time, :options

  def initialize
    @failed_account_ids = []
    @req_counter = 0
    @start_time = Time.now.to_i
    @options = { payload_type: 'workflow_sync', meta: { 'source' => 'search' } }
  end


  def check_redis
    BaseRedis.key_exists?("STOP_WF_SEARCH_MIGRAION")
  end

  def ensure_rpm
    time_elapsed = Time.now.to_i - @start_time
    if time_elapsed < 60
      puts "sleeping for #{60 - time_elapsed} - account #{Account.current.id}"
      sleep(60 - time_elapsed)
    end
    @req_counter = 0
    @start_time = Time.now.to_i
  end

  def central_push(wf)
    payload = wf.collect_properties_v2(@options)
    payload[:event_uuid] = wf.event_uuid || wf.generate_event_id
    payload = { params: payload, version: 2 }
    res = FreshPipeReSync.new.perform(payload)
    @req_counter += 1 if res
  end

  def migrate_wf(shard_names, rpm)
    shard_names.each do |shard_name|
      Sharding.run_on_shard(shard_name) do
        AccountIterator.each(batch_size: 200) do |account|
          next unless account.active?
          account.make_current
          Account.current.workflows.where.not(status: Workflow::STATES[:archive]).find_each(batch_size: 500) do |wf|
            BaseRedis.set_key("WF_MIGRATION", Account.current.id) and break if check_redis
            central_push(wf)
            ensure_rpm if @req_counter >= rpm
          end
        rescue StandardError => e
          puts "account_id: #{account.id}"
          puts "exception: #{e.inspect}"
          puts '----------------------------------'
          @failed_account_ids.push(account.id)
        ensure
          break if check_redis
          Account.reset_current
        end
      end
      puts "breaking since redis key presents" and break if check_redis
    end
    puts "failed accounts - #{@failed_account_ids}"
  end
end
