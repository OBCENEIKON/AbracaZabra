class CreateMailMessages < ActiveRecord::Migration
  def change
    create_table :mail_messages do |t|
      t.string :subject, null: false
      t.text :body, null: false
      t.string :environment
      t.string :status
      t.string :severity, null: false
      t.datetime :message_date, null: false
      t.boolean :whitelisted, null: false, default: false
      t.integer :zabbix_id, index: true
      t.integer :jira_id, index: true
      t.string :jira_key, index: true
      t.binary :mail_message, null: false
      t.datetime :deleted_at, index: true

      t.timestamps
    end
  end
end
