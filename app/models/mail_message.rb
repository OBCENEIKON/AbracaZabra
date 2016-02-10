require './lib/mail/abracazabra/abracazabra'

class MailMessage < ActiveRecord::Base
  include Mail::Abracazabra

  acts_as_paranoid

  def fetch
    ap 'fetch'
    if config[:abracazabra]['fetch_method'] == 'email'
      ap 'fetch_email'
      fetch_email
    else
      fetch_api
    end
  end

  def fetch_api

  end

  private

  def config
    config ||= {}
    config[:abracazabra] ||= Rails.configuration.x.abracazabra
    config[:atlassian] ||= Rails.configuration.x.atlassian
    config[:zabbix] ||= Rails.configuration.x.zabbix
    config
  end
end
