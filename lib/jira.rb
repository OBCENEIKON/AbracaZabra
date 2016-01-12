class Jira
  class << self
    def issue(message_id)
      @message = Message.find(message_id)

      if @message['status'] == config['zabbix']['text_descriptions']['problem']
        new_issue
      else
        close_issue
      end
    end

    def report
      query_json = {
          jql: "project = #{config['jira']['project_id']} and created >= '-2d'",
          fields: ['*all']
      }

      result = jira_request 'post', 'rest/api/2/search', query_json
      result = JSON.parse result

      totals result['issues']
      from_date = long_time(DateTime.now.yesterday.beginning_of_day.change(hour: 8))
      to_date = long_time(DateTime.now.beginning_of_day.change(hour: 8))

      @body = config['jira']['email']['body']
      replace({ /%total_alerts%/ => @total_alerts_text, /%from_date%/ => from_date, /%to_date%/ => to_date }, @body)

      if @total_alerts > 0
        @body += "\n\nDisaster: #{@disaster}\nHigh: #{@high}\nAverage: #{@average}\nWarning: #{@warning}\nUnknown: #{@unknown}"
        @body += "\n\nPlease find them below:\n\n"

        text_body @body
        html_body "#{@body}<ul>"

        result['issues'].each do |m|
          text_body "\t* #{m['fields']['summary']}\n  - #{config['jira']['url']}/browse/#{m['key']}"

          triggered_body m
          comments m
        end

        html_body '</ul>'
      end

      to = config['jira']['email']['to']
      from = config['jira']['email']['from']
      subject = config['jira']['email']['subject']

      Mail.deliver do
        to to
        from from
        subject subject

        text_part do
          body @text_body
        end

        html_part do
          content_type 'text/html; charset=UTF-8'
          body @html_body
        end
      end
    end

    private

    def new_issue
      message_json = {
          fields: {
              project: {
                  id: config['jira']['project_id']
              },
              issuetype: {
                  id: config['jira']['issue_id']
              },
              priority: {
                  id: @message['severity']
              },
              summary: @message['subject'],
              description: @message['body']
          }
      }

      message_json['fields']['assignee'] = config['abracazabra']['admin'] if @message['subject'] == config['abracazabra']['email']['subject']

      result = jira_request 'post', 'rest/api/2/issue', message_json
      result = JSON.parse(result)

      @message.jira_id = result['id']
      @message.jira_key = result['key']
      @message.save
    end

    def close_issue
      jira = Message.find_by(zabbix_id: @message['zabbix_id'], status: config['zabbix']['text_descriptions']['problem'])

      message_json = {
          body: @message['body']
      }

      jira_request 'post', "rest/api/2/issue/#{jira.jira_key}/comment", message_json

      message_json = {
          transition: {
            id: 21
          }
      }

      result = jira_request 'post', "rest/api/2/issue/#{jira.jira_key}/transitions", message_json
      result = JSON.parse(result)

      @message.jira_id = result['id']
      @message.jira_key = result['key']
      @message.save
    end

    private

    def jira_request(method, path, payload)
      user = config['jira']['username']
      pass = config['jira']['password']
      auth = 'Basic ' + Base64.encode64("#{user}:#{pass}").chomp

      resource = RestClient::Resource.new("#{config['jira']['url']}/#{path}")
      resource.send(method, payload.to_json, Authorization: auth, content_type: :json, accept: :json)
    end

    def long_time(time)
      format = '%A %B, %e %Y at %I:%M %P'
      time.is_a?(DateTime) ? time.strftime(format) : DateTime.parse(time).strftime(format)
    end

    def short_time(time)
      DateTime.parse(time).strftime('%-m/%-d/%y %I:%M %P')
    end

    def config
      # Had to reload the config file here, because for some reason some of the configuration options were missing
      Rails.application.config.x.abracazabra ||= Rails.application.config_for(:abracazabra)
    end

    def replace(map, string)
      map.inject(string) { |str, mapping| ap string.gsub(*mapping) }
    end

    def totals(issues)
      @average = @warning = @high = @disaster = @unknown = 0

      issues.each do |m|
        @average = m['fields']['priority']['id'].to_i == config['jira']['priorities']['standard'] ? @average + 1 : @average
        @warning = m['fields']['priority']['id'].to_i == config['jira']['priorities']['minor'] ? @warning + 1 : @warning
        @high = m['fields']['priority']['id'].to_i == config['jira']['priorities']['major'] ? @high + 1 : @high
        @disaster = m['fields']['priority']['id'].to_i == config['jira']['priorities']['critical'] ? @disaster + 1 : @disaster
        @unknown = m['fields']['priority']['id'].to_i == config['jira']['priorities']['trivial'] ? @unknown + 1 : @unknown
      end

      @total_alerts = @average + @warning + @high + @disaster + @unknown
      @total_alerts_text = @total_alerts > 1 || @total_alerts == 0 ? "were #{@total_alerts} alerts" : "was #{@total_alerts} alert"
    end

    def text_body(string = '')
      @text_body = '' if @text_body.nil?
      @text_body += string
    end

    def html_body(string = '')
      @html_body = '' if @html_body.nil?
      @html_body += string
      replace({/\n/ => '<br />'}, @html_body)
    end

    def time_diff(start_time, end_time)
      seconds_diff = (start_time - end_time).to_i.abs

      hours = seconds_diff / 3600
      seconds_diff -= hours * 3600

      minutes = seconds_diff / 60
      seconds_diff -= minutes * 60

      seconds = seconds_diff

      time = []
      time << "#{hours} hours" if hours > 0
      time << "#{minutes} hours" if minutes > 0
      time << "#{seconds} hours" if seconds > 0
      time.to_sentence
    end

    def triggered_body(m)
      triggered = long_time(m['fields']['created'])
      text_body "\t  - Triggered #{triggered}"
      html_body "<li><a href=\"#{config['jira']['url']}/browse/#{m['key']}\">#{m['fields']['summary']}</a></li>"
      html_body "<li><ul><li>Triggered #{triggered}</li>"

      unless m['fields']['resolution'].blank?
        resolved = long_time(m['fields']['resolutiondate'])
        text_body "\t  - Resolved #{resolved}"
        html_body "<li>Resolved #{resolved}</li>"
        total_time = time_diff(Time.parse(resolved), Time.parse(triggered))
        text_body "\t  - Total time awry: #{total_time}"
        html_body "<li>Total time awry: #{total_time}</li>"
      end

      html_body '</ul>'
    end

    def comments(m)
      unless m['fields']['comment']['comments'].blank?
        text_body "\t  - Activity:\n"
        html_body '<ul><li>Activity:</li><ul>'

        m['fields']['comment']['comments'].each do |c|
          comment_date = short_time(m['fields']['created'])
          text_body "\t    - #{c['author']['name']} [#{comment_date}]: #{c['body']}\n"
          html_body "<li><a href=\"mailto:#{c['author']['emailAddress']}\">#{c['author']['name']}</a> [#{comment_date}]: #{m['body']}</li>"
        end

        html_body '</ul></li></ul>'
      end
    end
  end
end
