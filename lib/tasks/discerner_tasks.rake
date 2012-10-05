# desc "Explaining what the task does"
# task :discerner do
#   # Task goes here
# end

namespace :discerner do
  task :environment do
    require './spec/dummy/config/environment'
  end
end