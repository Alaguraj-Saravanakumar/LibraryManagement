class MigrateWf
  attr_accessor :failed_account_ids, :req_counter, :start_time, :options

  def initialize
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
      Rails.logger.info "sleeping for #{60 - time_elapsed} - account #{Account.current.id}"
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

  def migrate_wf(shard_name, rpm)
    Sharding.run_on_shard(shard_name) do
      acc = BaseRedis.get_key('WF_MIGRATION')
      if acc.present?
        Rails.logger.info "Fetching from redis key - account #{acc.to_i}"
        meta = { batch_size: 200, conditions: ['id >= ?', acc.to_i] }
      else
        meta = { batch_size: 200 }
      end
      AccountIterator.each(meta) do |account|
        next unless account.active?
        Rails.logger.info "Running migration for account #{account.id}"
        account.make_current
        ActsAsTenant.current_tenant = account
        BaseRedis.set_key("WF_MIGRATION", Account.current.id)
        Account.current.all_workflows.find_each(batch_size: 300) do |wf|
          break if check_redis
          central_push(wf)
          ensure_rpm if @req_counter >= rpm
        end
      rescue StandardError => e
        puts "account_id: #{account.id}"
        puts "exception: #{e.inspect}"
        puts '----------------------------------'
        failed_acc = BaseRedis.get_key('WF_MIGRATION_FAILED_ACCOUNT_IDS') || []
        failed_acc.push(account.id)
        BaseRedis.set_key('WF_MIGRATION_FAILED_ACCOUNT_IDS', failed_acc)
      ensure
        puts "breaking since redis key presents" and break if check_redis
        Account.reset_current
      end
      BaseRedis.remove_key("WF_MIGRATION")
    end
    puts "failed accounts - #{BaseRedis.get_key('WF_MIGRATION_FAILED_ACCOUNT_IDS')}"
    BaseRedis.remove_key('WF_MIGRATION_FAILED_ACCOUNT_IDS')
  end
end