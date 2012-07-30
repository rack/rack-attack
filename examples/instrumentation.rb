
# Log blacklists & throttles
ActiveSupport::Notifications.subscribe('rack.attack.blacklist') do |name, start, finish, request_id, req|
  puts req.inspect
end

ActiveSupport::Notifications.subscribe('rack.attack.throttle') do |name, start, finish, request_id, req|
  puts req.inspect
end
