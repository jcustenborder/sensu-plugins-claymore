# frozen_string_literal: true

require 'sensu-plugin/metric/cli'
require 'socket'
require 'json'
require 'sensu-plugins-claymore'

module SensuPluginsClaymore
  module Dual
    class ClaymoreMetricsJSON < Sensu::Plugin::Metric::CLI::JSON
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
        output response
        ok
      end
    end
  end
end
