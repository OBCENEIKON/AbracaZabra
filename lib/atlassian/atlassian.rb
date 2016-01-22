module Atlassian
  def config
    config ||= {}
    config[:abracazabra] ||= Rails.configuration.x.abracazabra
    config[:atlassian] ||= Rails.configuration.x.atlassian
    config[:zabbix] ||= Rails.configuration.x.zabbix
    Delayed::Worker.logger.debug('Config')
    Delayed::Worker.logger.debug(config)
    config
  end
end