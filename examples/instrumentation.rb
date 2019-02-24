ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
  puts payload[:request].inspect
end
