class Message < ActiveRecord::Base
  acts_as_paranoid

  def messages
    begin
      Mail.find(what: :first, delete_after_find: true) do |m|
        next unless whitelisted? m

        data = m.body.to_s.split("\n").reject(&:empty?)

        message = {
            subject: m.subject,
            body: m.body.to_s,
            status: config['zabbix']['text_descriptions']['problem'],
            severity: config['jira']['priorities']['trivial'],
            whitelisted: whitelisted?(m),
            zabbix_id: nil,
            message_date: m.date.to_s,
            mail_message: Marshal.dump(m)
        }

        if data.include? config['zabbix']['text_descriptions']['zabbix_id']
          data.each do |d|
            line = /^([a-zA-Z\s]+):(.+)$/.match(d)

            case line[1]
            when config['zabbix']['text_descriptions']['trigger_status']
              @status = line[2].strip!
            when config['zabbix']['text_descriptions']['trigger_severity']
              case line[2].strip!
              when config['zabbix']['text_descriptions']['disaster']
                @priority = config['jira']['priorities']['critical']
              when config['zabbix']['text_descriptions']['High']
                @priority = config['jira']['priorities']['major']
              when config['zabbix']['text_descriptions']['Warning']
                @priority = config['jira']['priorities']['minor']
              when config['zabbix']['text_descriptions']['Average']
                @priority = config['jira']['priorities']['standard']
              else
                @priority = config['jira']['priorities']['trivial']
              end
            when config['zabbix']['text_descriptions']['zabbix_id']
              @zabbix_id = line[2].strip!
            end
          end

          message =  {
              subject: m.subject,
              body: m.body.to_s,
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

        Jira.delay.issue(message.id)
      end
    rescue
        message = {
            subject: config['abracazabra']['email']['subject'],
            body: $!,
            status: config['zabbix']['text_descriptions']['problem'],
            severity: config['jira']['priorities']['major'],
            whitelisted: true,
            message_date: Time.now.to_s,
            mail_message: Marshal.dump($!)
        }

        message = Message.create message

        Jira.delay.issue(message.id)
    end
  end

  private

  def whitelisted?(message)
    # You would expect true if it's whitelisted and false if not, hence the !
    !(config['abracazabra']['email']['whitelist'] & message.from).empty?
  end

  def config
    Rails.configuration.x.abracazabra
  end
end
