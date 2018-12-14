task :create_recharge_webhook => :environment do
  Webhooks.create_recharge
end

task :create_recharge_subscription_webhook => :environment do
  Webhooks.create_recharge_subscription
end