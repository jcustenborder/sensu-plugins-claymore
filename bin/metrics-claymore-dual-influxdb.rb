require 'sensu-plugin/metric/cli'
require 'socket'
require 'json'
require 'sensu-plugins-claymore'

module SensuPluginsClaymore
  module Dual
    class ClaymoreMetricsInfluxdb < Sensu::Plugin::Metric::CLI::Influxdb
      option :host,
             description: 'Claymore dual host',
             short: '-h HOST',
             long: '--host HOST',
             default: 'localhost'

      option :port,
             description: 'Claymore dual management port',
             short: '-p PORT',
             long: '--port PORT',
             proc: proc(&:to_i),
             default: 4000

      def run
        dual = SensuPluginsClaymore::Dual::ClaymoreDualClient.new config
        begin
          response = dual.execute
        rescue Errno::ECONNREFUSED => ex
          critical(ex.message)
          return
        end

        output 'claymore.dual.uptime', response['uptime']
        output 'claymore.dual.eth.hashrate', response['eth']['hashrate']
        output 'claymore.dual.eth.shares', response['eth']['shares']
        output 'claymore.dual.eth.rejects', response['eth']['rejects']
        output 'claymore.dual.alt.hashrate', response['alt']['hashrate']
        output 'claymore.dual.alt.shares', response['alt']['shares']
        output 'claymore.dual.alt.rejects', response['alt']['rejects']

        response['gpu'].each do |index, values|
          output 'claymore.dual.eth.hashrate', "gpu=#{index}", values['eth_hashrate']
          output 'claymore.dual.alt.hashrate', "gpu=#{index}", values['alt_hashrate']
          output 'claymore.dual.temperature', "gpu=#{index}", values['temperature']
          output 'claymore.dual.fanspeed', "gpu=#{index}", values['fanspeed']
        end
        ok
      end
    end
  end
end
