require "redis"

redis_conf  = Rails.application.config_for(:redis)
REDIS = Redis.new(:host => redis_conf["host"], :port => redis_conf["port"])