class Message < ActiveRecord::Base
  # include Atlassian::Jira

  acts_as_paranoid

  def messages
    begin
      Mail.find(what: :first, delete_after_find: true) do |m|
        next unless whitelisted? m

        data = m.body.to_s.split("\n").reject(&:empty?)

        message = {
            subject: m.subject,
            body: m.body.to_s,
            environment: 'Unknown',
            status: config[:zabbix]['text_descriptions']['problem'],
            severity: config[:atlassian]['jira']['priorities']['trivial'],
            whitelisted: whitelisted?(m),
            zabbix_id: nil,
            message_date: m.date.to_s,
            mail_message: Marshal.dump(m)
        }

        if m.body.to_s.include? config[:zabbix]['text_descriptions']['zabbix_id']
          environment = m.subject[0, 3]

          data.each do |d|
            line = /^([a-zA-Z\s]+):(.+)$/.match(d)

            case line[1]
            when config[:zabbix]['text_descriptions']['trigger_status']
              @status = line[2].strip!
            when config[:zabbix]['text_descriptions']['trigger_severity']
              case line[2].strip!
              when config[:zabbix]['text_descriptions']['disaster']
                @priority = config[:atlassian]['jira']['priorities']['critical']
              when config[:zabbix]['text_descriptions']['High']
                @priority = config[:atlassian]['jira']['priorities']['major']
              when config[:zabbix]['text_descriptions']['Warning']
                @priority = config[:atlassian]['jira']['priorities']['minor']
              when config[:zabbix]['text_descriptions']['Average']
                @priority = config[:atlassian]['jira']['priorities']['standard']
              else
                @priority = config[:atlassian]['jira']['priorities']['trivial']
              end
            when config[:zabbix]['text_descriptions']['zabbix_id']
              @zabbix_id = line[2].strip!
            end
          end

          message =  {
              subject: m.subject,
              body: m.body.to_s,
              environment: environment,
              status: @status,
              severity: @priority,
              whitelisted: whitelisted?(m),
              zabbix_id: @zabbix_id,
              message_date: m.date.to_s,
              mail_message: Marshal.dump(m),
          }
        end

        message = Message.create message

        m.skip_deletion unless message.persisted?

        Atlassian::Jira.delay.issue(message.id)
      end
    rescue Exception
      ap $!.inspect
      exception = { class: $!.class, message: $!.to_s, backtrace: $!.backtrace }

      ap config
      message = {
          subject: config[:abracazabra]['email']['subject'],
          body: $!,
          environment: 'AbracaZabra',
          status: config[:zabbix]['text_descriptions']['problem'],
          severity: config[:atlassian]['jira']['priorities']['critical'],
          whitelisted: true,
          message_date: Time.now.to_s,
          mail_message: Marshal.dump(exception)
      }

      message = Message.create message

      one_hour_ago = DateTime.now - (1.0 / 24)

      last_message = Message.where(subject: message.subject, body: message.body, created_at: one_hour_ago..DateTime.now).first

      message.zabbix_id = last_message.nil? ? message.id : last_message.zabbix_id
      message.save

      Atlassian::Jira.delay.issue(message.id)
    end
  end

  private

  def whitelisted?(message)
    # You would expect true if it's whitelisted and false if not, hence the !
    !(config[:zabbix]['email']['whitelist'] & message.from).empty?
  end

  def config
    config ||= {}
    config[:abracazabra] ||= Rails.configuration.x.abracazabra
    config[:atlassian] ||= Rails.configuration.x.atlassian
    config[:zabbix] ||= Rails.configuration.x.zabbix
    config
  end
end
