class ApplicationController < ActionController::API
  include ActionController::ImplicitRender
  acts_as_token_authentication_handler_for User
  respond_to :json

  def throttle(endpoint_name: :default)

    throttle_info = Rails.application.config_for(:throttle)
  	throttle_time_window = throttle_info["#{endpoint_name}"]["throttle_time_window"]
    throttle_max_requests = throttle_info["#{endpoint_name}"]["throttle_max_requests"]

    if current_user.present?
      key = "user:#{current_user.id}_request_#{endpoint_name}"
    else
      key = "user:#{request.remote_ip}_request_#{endpoint_name}"
    end
    begin
      count = REDIS.get(key)
	    if count.nil?
	      REDIS.set(key, 0)
	      REDIS.expire(key, throttle_time_window)
	      return true
	    end
      if count.to_i >= throttle_max_requests
	      render :status => 429, :json => {:message => "You have fired too many requests. Please wait for some time."}
	      return
	    end
      REDIS.incr(key)
	    true
	  rescue => error
	  	puts error.inspect
        ### send email or SMS notification to developer group
        UserNotifier.send_redis_down_email(Rails.application.config.admin_email)
	  end
  end
end
