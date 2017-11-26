#!/usr/bin/env ruby
#
# check-claymore-dual-temperature.rb
#
# DESCRIPTION:
#   This plugin is used to check the temperature of the GPUs on the miner host.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   Checks that the GPUs on the host are below thresholds
#   check-claymore-dual-temperature.rb
#
#
# LICENSE:
#   Copyright 2017 Jeremy Custenborder <jcustenborder@gmail.com>
#   Released under the Apache 2.0 license; see LICENSE
#   for details.

require 'sensu-plugin/check/cli'

module SensuPluginsClaymore
  module Dual
    class GPUTemperatureCheck < Sensu::Plugin::Check::CLI
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

      option :gpu,
             description: 'GPU index to check for. -1 to check for all indexes.',
             short:       '-g GPU',
             long:        '--gpu GPU',
             proc:        proc(&:to_i),
             default:     -1

      option :critical,
             description: 'Critical temperature for a GPU',
             short:       '-c CRITICAL',
             long:        '--critical CRITICAL',
             proc:        proc(&:to_i),
             default:     100

      option :warning,
             description: 'Warning temperature for a GPU',
             short:       '-w WARNING',
             long:        '--warning WARNING',
             proc:        proc(&:to_i),
             default:     90

      def run
        dual = SensuPluginsClaymore::Dual::ClaymoreDualClient.new config
        begin
          response = dual.execute
        rescue Errno::ECONNREFUSED => ex
          critical(ex.message)
          return
        end

        gpu_warn = {}
        gpu_crit = {}
        gpu_ok   = {}

        response['gpu'].each do |index, values|
          next unless index == config[:gpu] || config[:gpu] == -1
          temperature     = values['temperature']
          gpu_crit[index] = temperature if temperature >= config[:critical]
          gpu_warn[index] = temperature if temperature >= config[:warning]
          gpu_ok[index]   = temperature
        end

        unless gpu_crit.empty?
          critical "GPU temperature critical: #{gpu_crit.map { |k, v| "#{k} = #{v}c" }.join(', ')}"
        end

        unless gpu_warn.empty?
          warning "GPU temperature warning: #{gpu_warn.map { |k, v| "#{k} = #{v}c" }.join(', ')}"
        end

        if gpu_crit.empty? && gpu_warn.empty? && gpu_ok.empty?
          critical 'No GPUs were checked. Check GPU index.'
        end

        ok "GPU temperature ok: #{gpu_ok.map { |k, v| "#{k} = #{v}c" }.join(', ')}"
      end
    end
  end
end
