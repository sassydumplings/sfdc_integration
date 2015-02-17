class FieldMap

  def self.get_customer_metrics(user_id)

    begin
      one_record = MyFake::API::CustomerMetrics.get_metrics(user_id)
    rescue
      one_record = {}
    end
  end

  def self.build_account_update_record(array)

    array.each do |k,v|
      @user_id = k
      @acct_id = v
    end

    metrics = get_customer_metrics(@user_id.to_i)

    update_record = Hash.new
    update_record.store("id", @acct_id)

    #   config/initializers/field_map.rb is the conversion of hash keys
    #  to the Salesforce API names
    #  FYI - the names end in two underscores
    metrics.each do |k, v|
      m_key = SFDC_MAP[k.to_sym]
      m_value = v
      if m_key
        update_record.store(m_key, m_value)
      end
    end

    return update_record
  end

end