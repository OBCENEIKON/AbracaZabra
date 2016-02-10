unless defined? Rake::Task
  scheduler = Rufus::Scheduler.new

  m = MailMessage.new

  scheduler.every '1m', first: :now do
    m.fetch
  end

  scheduler.cron '15 8 * * *' do
    Jira.report
  end
end
