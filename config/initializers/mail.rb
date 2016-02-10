config ||= {}
config[:abracazabra] ||= Rails.configuration.x.abracazabra

Mail.defaults do
  retriever_method config[:abracazabra]['email']['method'].to_sym, address: config[:abracazabra]['email']['address'],
                    port: config[:abracazabra]['email']['port'],
                    user_name: config[:abracazabra]['email']['username'],
                    password: config[:abracazabra]['email']['password'],
                    enable_ssl: config[:abracazabra]['email']['ssl']
end
