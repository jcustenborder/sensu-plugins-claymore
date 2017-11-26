#!/usr/bin/env ruby
#
# check-claymore-dual-eth-hashrate.rb
#
# DESCRIPTION:
#   This plugin checks the ETH hashrate of the miner instance.
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
#   Check the total hashrate for the miner instance.
#   check-claymore-dual-eth-hashrate.rb --critical 100 --warning 120
#
#   Check the hashrate of an individual gpu
#   check-claymore-dual-eth-hashrate.rb --critical 100 --warning 120 --gpu 0
#
# LICENSE:
#   Copyright 2017 Jeremy Custenborder <jcustenborder@gmail.com>
#   Released under the Apache 2.0 license; see LICENSE
#   for details.

require 'sensu-plugin/check/cli'

module SensuPluginsClaymore
  module Dual
    class ETHHashrateCheck < Sensu::Plugin::Check::CLI
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
             description: 'GPU index to check for. -1 to check for the total hashrate.',
             short:       '-g GPU',
             long:        '--gpu GPU',
             proc:        proc(&:to_i),
             default:     -1

      option :critical,
             description: 'Minimum hashrate to trigger critical.',
             short:       '-c CRITICAL',
             long:        '--critical CRITICAL',
             proc:        proc(&:to_f),
             required:    true

      option :warning,
             description: 'Minimum hashrate to trigger warning.',
             short:       '-w WARNING',
             long:        '--warning WARNING',
             proc:        proc(&:to_f),
             required:    true

      def run
        dual = SensuPluginsClaymore::Dual::ClaymoreDualClient.new config
        begin
          response = dual.execute
        rescue Errno::ECONNREFUSED => ex
          critical(ex.message)
          return
        end

        if config[:gpu] == -1
          eth_hashrate = response['eth']['hashrate']
          critical "ETH hashrate of #{eth_hashrate} is less than #{config[:critical]}" if config[:critical] > eth_hashrate
          warning "ETH hashrate of #{eth_hashrate} is less than #{config[:warning]}" if config[:warning] > eth_hashrate
          ok "ETH hashrate of #{eth_hashrate} is ok."
        else
          gpu_data = response['gpu'][config[:gpu]]
          critical "GPU #{config[:gpu]} not found." if gpu_data.nil?
          eth_hashrate = response['gpu'][config[:gpu]]['eth_hashrate']
          critical "GPU(#{config[:gpu]}) ETH hashrate of #{eth_hashrate} is less than #{config[:critical]}" if config[:critical] > eth_hashrate
          warning "GPU(#{config[:gpu]}) ETH hashrate of #{eth_hashrate} is less than #{config[:warning]}" if config[:warning] > eth_hashrate
          ok "GPU(#{config[:gpu]}) ETH hashrate of #{eth_hashrate} is ok."
        end
      end
    end
  end
end
