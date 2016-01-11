unless defined? Rake::Task
  scheduler = Rufus::Scheduler.new

  m = Message.new

  scheduler.every '1m', first: :now do
    m.messages
  end

  scheduler.cron '15 8 * * *' do
    Jira.report
  end
end
