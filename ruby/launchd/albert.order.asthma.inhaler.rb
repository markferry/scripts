require File.expand_path('~/Repos/scripts/ruby/lib/utilities.rb')
require '/Users/Albert/Repos/scripts/ruby/lib/encrypter.rb'
require '/Users/Albert/Repos/scripts/ruby/lib/selenium/nevil-road-surgery.rb'

nrs = NevilRoadSurgery.new(
    Encrypter.new.decrypt(NevilRoadUsername),
    Encrypter.new.decrypt(NevilRoadPassword)
)

begin
    nrs.orderAsthma('single', true)
rescue Exception => e
    cronLog"NevilRoad: Attempt to order inhalers failed with message: #{e.message}."
end