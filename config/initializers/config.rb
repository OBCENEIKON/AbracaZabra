Rails.application.config.x.abracazabra = Rails.application.config_for(:abracazabra)
Rails.application.config.x.atlassian = Rails.application.config_for(:atlassian)
Rails.application.config.x.zabbix = Rails.application.config_for(:zabbix)

config ||= {}
config[:abracazabra] ||= Rails.application.config.x.abracazabra
config[:atlassian] ||= Rails.application.config.x.atlassian
config[:zabbix] ||= Rails.application.config.x.zabbbix