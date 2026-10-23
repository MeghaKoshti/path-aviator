# Demo data for local development and the public demo account.
# Safe to run any number of times: re-running resets the demo account to the
# state described in app/models/demo_account.rb.

# In production the demo account is opt-in. db:prepare seeds every brand-new
# database, and a private install shouldn't get a login everyone knows.
if DemoAccount.enabled?
  DemoAccount.reset!
else
  puts "Skipped the demo account. Run with SEED_DEMO=1 to create it."
end
