def log(message, *additional_tags)
  tags = [Account.current.try(:id)]
  tags.concat(additional_tags)
  Rails.logger.tagged(*tags) do
    Rails.logger.info(message)
  end
end

def update_field_choice_mapping(field, choice_ids, workspace, account)
  mapping = field.choice_mapping_for_ws(workspace)
  log(mapping.attributes, 'CHOICES_BEFORE_UPDATE', 'BIZ_AGENT_UPDATE')
  mapping.enabled_choices = choice_ids
  mapping.save!
  Cache::Memcache::Workspace.clear_field_caches(account_id: account.id, entity: 'Helpdesk::TicketField', workspace_id: workspace.display_id)
end




def move_ticket_types(workspace, type_field, display_id_by_name)
  enabled_types = workspace.ticket_types_from_cache.map(&:value)
  business_ws_ticket_types = TicketConstants::SR_TYPES_BY_NAME.reject { |a| a if a.include?(TicketConstants::SERVICE_REQUEST) }.keys
  allowed_ticket_types = workspace.it_like_template? ? TicketConstants::IT_WORKSPACE_TYPES.keys : business_ws_ticket_types
  restricted_types = (enabled_types - allowed_ticket_types)
  return unless restricted_types.present?
  result_types = []
  result_type_ids = []
  result_types = enabled_types - restricted_types
  if workspace.business_workspace?
    result_types = [TicketConstants::REQUEST] if result_types.blank?
    update_type = result_types.last
  elsif workspace.it_like_template?
    result_types = [TicketConstants::SERVICE_REQUEST] if result_types.blank?
    result_types << TicketConstants::SERVICE_REQUEST if !result_types.include?(TicketConstants::SERVICE_REQUEST)
    update_type = TicketConstants::SERVICE_REQUEST
  end
  result_type_ids = result_types.map { |k| display_id_by_name[k] }
  update_field_choice_mapping(type_field, result_type_ids, workspace, Account.current)
  update_tickets(workspace, restricted_types, update_type)
end

def update_tickets(workspace, restricted_types, result_type)
  tickets = workspace.tickets
  tickets.find_in_batches do |ticket_batch|
    ticket_batch.each do |ticket|
      if restricted_types.include?(ticket.ticket_type)
        ticket.ticket_type = result_type.to_s
      end
      handle_association(ticket) if workspace.business_workspace?
      ticket.save!
    end
  end
end

def handle_association(ticket)
  handle_change_association(ticket, 'change') if ticket.change.present?
  handle_change_association(ticket, 'change_cause') if ticket.change_cause.present?
  handle_problem_association(ticket) if ticket.problem.present?
end

def handle_problem_association(ticket)
  log("ticket: #{ticket.id} problem_id: #{ticket.try(:itil_ticket).try(:problem_id)}", 'PROBLEM_ASSOC_BEFORE_UPDATE', 'BIZ_AGENT_UPDATE')
  ticket.itil_ticket.problem_id = nil
end

def handle_change_association(ticket, type)
  log("ticket: #{ticket.id} type: #{type} association_id: #{ticket.try(:itil_ticket).try(:safe_send, "#{type.singularize}_id")}", 'CHANGE_ASSOC_BEFORE_UPDATE', 'BIZ_AGENT_UPDATE')
  ticket.itil_ticket.safe_send("#{type.singularize}_id=", nil)
end

def update_pcr(workspace)
  update_itil_modules(workspace.problems)
  update_itil_modules(workspace.itil_changes)
  update_itil_modules(workspace.releases)
end

def update_itil_modules(itil_items)
  itil_items.find_in_batches do |itil_batch|
    itil_batch.each do |itil_item|
      itil_item.workspace_id = Workspace::PRIMARY_WORKSPACE_DISPLAY_ID
      itil_item.save!
    end
  end
end

def reset_workspace_privileges(account)
  account.agents.each do |agent|
    agent.workspace_privileges.each do |workspace_privilege|
      log(workspace_privilege.attributes, 'WORKSPACE_PRIVILEGE_BEFORE_UPDATE', 'BIZ_AGENT_UPDATE')
      workspace_privilege.save
    end
  end
end

Rails.logger.info("959875cf07b0249381af24b311a88acf")
account_ids = [537149,539312,541014,544747,551717,552653,555440,555688,557139,559602,562315,564818,565089,565746,566060,571895]
it_types = TicketConstants::IT_WORKSPACE_TYPES.keys
business_types = TicketConstants::SR_TYPES_BY_NAME.reject { |a| a if a.include?(TicketConstants::SERVICE_REQUEST) }.keys
account_ids.each do |account_id|
  Sharding.select_shard_of(account_id) do
    begin
      account = Account.find(account_id).make_current
      next if (Account.current.esm_enhancements_enabled? && Account.current.business_agent_restriction?) || !Account.current.esm_enhancements_enabled?
      
      ws_data = []
      type_field = Account.current.ticket_fields.find_by(field_type: 'default_ticket_type')
      display_id_by_name = type_field.picklist_values.each_with_object({}) { |pv, hsh| hsh[pv.value] = pv.display_id }
      workspaces = Account.current.workspaces_from_cache_by_display_ids

      workspaces.each do |ws_id, workspace|
        next if workspace.global_workspace?
        workspace.make_current
        update_pcr(workspace) if workspace.business_workspace?
        type_values = workspace.ticket_types_from_cache.map(&:value)
        move_ticket_types(workspace, type_field, display_id_by_name) if (workspace.business_workspace? && (type_values & it_types).present?) || (workspace.it_like_template? && (type_values & business_types).present?)
      end

      Account.current.enable_business_agent_restriction!
      puts "enabled business_agent_restriction for account - #{Account.current.id} - #{Account.current.business_agent_restriction?}"
      reset_workspace_privileges(Account.current)
    rescue => exception
      puts "Error in updating for account #{account.id} exception - #{exception.message}"
    ensure
      Account.reset_current
    end
  end
end
