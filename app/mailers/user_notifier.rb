class UserNotifier < ActionMailer::Base
  default :from => 'baseapi@example.com'

  ### send email notification when redis server down
  def send_redis_down_email(email)
    @user = user
    mail( :to => @user.email, :subject => )
    mail(:to => email, :subject => "[#{Rails.env}]Redis server down") do |format|
		  format.text do
		    render :text => "Redis server is down, please check it !"
		  end
		end
  end
end