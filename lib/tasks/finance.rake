namespace :finance do
  desc "Import a captured Google Sheet into an existing user's finance workspace (FILE=... EMAIL=...)"
  task import: :environment do
    user = User.find_by!(email: ENV.fetch("EMAIL"))
    Finance::SheetImporter.new(user, JSON.parse(File.read(ENV.fetch("FILE")))).import!
    puts "Imported #{user.asset_accounts.count} accounts, #{user.cash_entries.count} entries, #{user.money_tasks.count} tasks, #{user.asset_snapshots.count} monthly snapshots."
  end
end
