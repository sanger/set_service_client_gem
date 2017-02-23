require_relative "set_service_client/version"
require "faraday"
require "zipkin-tracer"

module SetServiceClient
	def self.post(name)
		data = {:data=>{:type=>"sets", :attributes=>{:name=>name}}}
		conn = get_connection
		JSON.parse(conn.post('/api/v1/sets', data.to_json).body)
	end

	def self.clone_set(set_uuid, new_name)
		data = {data: {attributes: {name: new_name}}}
		conn = get_connection
		conn.headers['Accept'] = 'application/vnd.api+json'
		JSON.parse(conn.post('/api/v1/sets/'+set_uuid+'/clone', data.to_json).body)
	end

	def self.lock_set(set_uuid)
		data = {data: {type: "sets", id: set_uuid, attributes: {locked: true}}}
		conn = get_connection
		conn.headers['Accept'] = 'application/vnd.api+json'
		conn.patch('/api/v1/sets/'+set_uuid, data.to_json)
	end

	def self.add_materials(set_uuid, materials)
		data = {:data => materials.compact.map{|m| {:id => m.uuid, :type => 'materials'}}}
		conn = get_connection
		conn.post('/api/v1/sets/'+set_uuid+'/relationships/materials', data.to_json)
	end

	def self.get_with_materials(set_uuid)
		conn = get_connection
		conn.headers = {'Accept' => 'application/vnd.api+json'}
		JSON.parse(conn.get('/api/v1/sets/'+set_uuid+'/relationships/materials').body)
	end

	def self.get_set(set_uuid)
		conn = get_connection
		conn.headers = {'Accept' => 'application/vnd.api+json'}
		JSON.parse(conn.get('/api/v1/sets/'+set_uuid).body)
	end

	def self.get_all
		conn = get_connection
		conn.headers = {'Accept' => 'application/vnd.api+json'}
		JSON.parse(conn.get('/api/v1/sets').body)
	end

private

	def self.get_connection
		conn = Faraday.new(:url => Rails.application.config.set_url) do |faraday|
			faraday.use ZipkinTracer::FaradayHandler, 'Set Service'
			faraday.proxy Rails.application.config.set_url_default_proxy
			faraday.request  :url_encoded
			faraday.response :logger
			faraday.adapter  Faraday.default_adapter
		end
		conn.headers = {'Content-Type' => 'application/vnd.api+json'}
		conn
	end
end
