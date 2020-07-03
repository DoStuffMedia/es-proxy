require "kemal"
require "./models/Elasticsearch"

before_all do |env|
  halt env, status_code: 403, response: "Forbidden" unless env.request.headers.has_key?("Api-Key")
  api_key = env.request.headers["Api-Key"].as(String)
  halt env, status_code: 403, response: "Forbidden" unless ["testing"].includes?(api_key)
  env.response.headers.add("Access-Control-Allow-Origin", "*")
  env.response.headers.add("Powered-By", "Dostuff")
  env.response.content_type = "application/json"
end

post "/" do |env|
  es_client = Elasticsearch.from_json env.request.body.not_nil!
  es_client.query.to_json
end

Kemal.config.powered_by_header = false
Kemal.run