module Atlassian
  class TeamCalendar
    class << self
      def assign_issue(json)
        Delayed::Worker.logger.debug('assign_issue')
        calendar_id = config[:atlassian]['jira']['calendar']['calendar_id']
        start_date = URI.escape(Date.today.beginning_of_month.to_s + 'T00:00:00Z')
        end_date = URI.escape(Date.today.end_of_month.to_s + 'T00:00:00Z')

        result = calendar_request 'get', "rest/calendar-services/1.0/calendar/events.json?subCalendarId=#{calendar_id}&start=#{start_date}&end=#{end_date}"
        result = JSON.parse(result)

        result.each do |e|
          start_date_time = DateTime.iso8601(e.originalStartDateTime)
          end_date_time = DateTime.iso8601(e.originalEndDateTime)
          timezone = start_date_time.strftime('%:z')
          current_date_time = DateTime.now.in_time_zone(timezone)

          if current_date_time > start_date_time && current_date_time < end_date_time
            json[:fields][:assignee] = { name: e.invitees[0].name }
          end
        end
      end

      private

      def calendar_request(method, path, payload = {})
        Delayed::Worker.logger.debug('calendar_request')
        user = config[:atlassian]['jira']['username']
        pass = config[:atlassian]['jira']['password']
        auth = 'Basic ' + Base64.encode64("#{user}:#{pass}").chomp

        Delayed::Worker.logger.debug('Path')
        Delayed::Worker.logger.debug("#{config[:atlassian]['jira']['calendar']['url']}/#{path}")
        Delayed::Worker.logger.debug('Auth')
        Delayed::Worker.logger.debug(auth)
        Delayed::Worker.logger.debug('Method')
        Delayed::Worker.logger.debug(method)
        resource = RestClient::Resource.new("#{config[:atlassian]['jira']['calendar']['url']}/#{path}")
        resource.send(method, Authorization: auth, content_type: :json, accept: :json)
      end

      # def config
      #   Atlassian.config
      # end
    end
  end
end
