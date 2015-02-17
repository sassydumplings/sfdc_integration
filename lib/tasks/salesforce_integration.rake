require 'salesforce_bulk_api'

namespace :salesforce_integration do

  #
  # Performs weekly CustomerMetrics / Salesforce sync
  # Sends an email when done
  #
  desc "Performs weekly CustomerMetrics / Salesforce sync"
  task :sync => :environment do

    # Initializations
    RakeLogger.info "[salesforce_integration][sync] Initializing..."

    # Current CRON Task run
    cron_task_log = CronTaskLog.new
    cron_task_log.namespace = "salesforce_integration"
    cron_task_log.task = "sync"
    cron_task_log.started_at = DateTime.now
    cron_task_log.success_count = 0
    cron_task_log.warning_count = 0
    cron_task_log.failure_count = 0
    RakeLogger.info "[salesforce_integration][sync] Starting..."

    # using two different gems to interact with Salesforce.com (SFDC)
    # databasedotcom is used to authenticate and query SFDC
    # queries return as objects form the soap request
    #
    # default host is login.salesforce.com
    # Databasedotcom::Client.new :host => "test.salesfoce.com", ...
    client = Databasedotcom::Client.new("config/databasedotcom.yml")

    # need the credentials in databasedotcom.yml and in the line below moved to env variables
    client.authenticate :username => your_username, :password => your_password


      records_to_update = Array.new
      # For each user

    MyFake::API::User.get_active_user_ids.split(",").each { |user_id|

        begin

          # find the account record in SFDC
          # - the id is the 18 digit SFDC account id
          # - the User_ID__c is your user id
          account = client.query("select id, User_ID__c from account where User_ID__c = '#{user_id}'")
          user_account = Hash.new
          user_account.store(account[0].User_ID__c, account[0].Id)

          if user_account
            updated_account = FieldMap.build_account_update_record(user_account)
            records_to_update.push(updated_account)
          end
          cron_task_log.success_count += 1

        rescue => e
          RakeLogger.error "[salesforce_integration][sync] Error: #{e.class}: #{e.message}"
          e.backtrace[0..5].each { |line| RakeLogger.error line; puts line }
          cron_task_log.failure_count += 1
        end

      }

      #
      # salesforce-bulk-api gem used the databasedotcom client to authentic
      # using this gem for the bulk upload to SFDC Account
      #
      salesforce = SalesforceBulkApi::Api.new(client)
      salesforce.update("Account", records_to_update)



    # Log current_sync_started_at as the next last_vendor_synced_at
    RakeLogger.info "[salesforce_integration][sync] Completed: #{cron_task_log.success_count} success, #{cron_task_log.warning_count} warning, #{cron_task_log.failure_count} failure"
    cron_task_log.ended_at = DateTime.now

    # Final: Send CRON task email report
    cron_task_log.deliver_email_report

  end


end