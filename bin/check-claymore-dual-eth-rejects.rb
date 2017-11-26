# frozen_string_literal: true

require 'sensu-plugin/check/cli'

module SensuPluginsClaymore
  module Dual
    class ETHRejectsCheck < Sensu::Plugin::Check::CLI
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

      option :critical,
             description: 'Minimum hashrate to trigger critical.',
             short:       '-c CRITICAL',
             long:        '--critical CRITICAL',
             proc:        proc(&:to_f),
             required:    true,
             default:     0.5

      option :warning,
             description: 'Minimum hashrate to trigger warning.',
             short:       '-w WARNING',
             long:        '--warning WARNING',
             proc:        proc(&:to_f),
             required:    true,
             default:     0.1

      def run
        dual = SensuPluginsClaymore::Dual::ClaymoreDualClient.new config
        begin
          response = dual.execute
        rescue Errno::ECONNREFUSED => ex
          critical(ex.message)
          return
        end

        shares  = response['eth']['shares']
        rejects = response['eth']['rejects']

        ok 'Rejects are 0.' if rejects.zero?
        critical 'All shares have been rejected' if shares.zero? && rejects.positive?
        reject_rate = Float(rejects) / Float(shares) * Float(100)

        critcal "Reject rate of #{reject_rate} exceeds #{config[:critical]}" if reject_rate > config[:critical]
        warning "Reject rate of #{reject_rate} exceeds #{config[:warning]}" if reject_rate > config[:warning]
        ok "Reject rate of #{reject_rate} is ok."
      end
    end
  end
end
