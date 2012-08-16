ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  puts req.inspect
end
