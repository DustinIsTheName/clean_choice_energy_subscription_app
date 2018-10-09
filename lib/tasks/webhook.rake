task :create_recharge_webhook => :environment do
  Webhooks.create_recharge
end