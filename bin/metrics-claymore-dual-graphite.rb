# frozen_string_literal: true

require 'sensu-plugin/metric/cli'
require 'socket'
require 'json'
require 'sensu-plugins-claymore'

module SensuPluginsClaymore
  module Dual
    class ClaymoreMetricsGraphite < Sensu::Plugin::Metric::CLI::Graphite
      option :host,
             description: 'Claymore dual host',
             short:       '-h HOST',
             long:        '--host HOST',
             default:     'localhost'

      option :port,
             description: 'Claymore dual management port',
             short:       '-p PORT',
             long:        '--port PORT',
             proc:        proc(&:to_i),
             default:     4000

      def run
        dual = SensuPluginsClaymore::Dual::ClaymoreDualClient.new config
        begin
          response = dual.execute
        rescue Errno::ECONNREFUSED => ex
          critical(ex.message)
          return
        end

        output 'version', response['version']
        output 'uptime', response['uptime']
        output 'total.eth.hashrate', response['eth']['hashrate']
        output 'total.eth.shares', response['eth']['shares']
        output 'total.eth.rejects', response['eth']['rejects']
        output 'total.alt.hashrate', response['alt']['hashrate']
        output 'total.alt.shares', response['alt']['shares']
        output 'total.alt.rejects', response['alt']['rejects']

        response['gpu'].each do |index, values|
          output "gpu.#{index}.eth.hashrate", values['eth_hashrate']
          output "gpu.#{index}.alt.hashrate", values['alt_hashrate']
          output "gpu.#{index}.temperature", values['temperature']
          output "gpu.#{index}.fanspeed", values['fanspeed']
        end

        ok
      end
    end
  end
end
