module V1
  class SessionsController < Devise::SessionsController
    wrap_parameters :user
    before_action do
      throttle(endpoint_name: :default)
    end

    def create
      user = AuthenticateUser.call(warden: warden).user
      respond_with(user, serializer: SessionSerializer)
    end
  end
end
