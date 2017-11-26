require 'socket'
require 'json'

module SensuPluginsClaymore
  class ClaymoreDual
    def initialize(config)
      @host = config[:host]
      @post = config[:port]
    end

    MAX_ATTEMPTS = 5

    def miner_getstat1

      count = 0
      socket = nil
      response_json = nil
      begin
        socket = TCPSocket.new @host, @post
        socket.puts '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}'
        response = socket.gets
        response_json = JSON.parse(response)
      rescue Errno::ECONNRESET => ex
        count += 1
        sleep(5) unless count <= MAX_ATTEMPTS
        retry unless count > MAX_ATTEMPTS
      ensure
        socket.close if socket
      end

      return response_json['result']
    end


    def execute
      output = {}

      result = miner_getstat1()

      version = result[0]
      output['version'] = version

      uptime = result[1]
      output['uptime'] = uptime.to_i

      eth_total = result[2].split(/;/).map(&:to_f)
      eth_hashrate = eth_total[0] / Float(1000)
      eth_shares = eth_total[1]
      eth_rejects = eth_total[2]

      output['eth'] = {
          'hashrate' => eth_hashrate,
          'shares' => eth_shares,
          'rejects' => eth_rejects,
      }

      output['gpu'] = {}

      eth_hashrates = result[3].split(/;/).map(&:to_f)
      index = 0
      eth_hashrates.each do |h|
        output['gpu'][index] = {
            'eth_hashrate' => h / Float(1000)
        }
        index += 1
      end

      alt_total = result[4].split(/;/).map(&:to_f)
      alt_hashrate = alt_total[0] / Float(1000)
      alt_shares = alt_total[1]
      alt_rejects = alt_total[2]
      output['alt'] = {
          'hashrate' => alt_hashrate,
          'shares' => alt_shares,
          'rejects' => alt_rejects,
      }

      desc_hashrates = result[5].split(/;/)
      index = 0
      desc_hashrates.each do |d|
        hashrate = nil
        if d == 'off'
          hashrate = Float(0)
        else
          hashrate = Float(d) / Float(1000)
        end
        output['gpu'][index]['alt_hashrate'] = hashrate
        index += 1
      end

      global_temperature = result[6].split(/;/).map(&:to_i)
      index = 0
      while (!global_temperature.empty?)
        fanspeed = global_temperature.pop
        temp = global_temperature.pop
        output['gpu'][index]['temperature'] = temp
        output['gpu'][index]['fanspeed'] = fanspeed
        index += 1
      end

      #TODO Comeback and do something with the pools.
      pools = result[7]
      return output
    end
  end
end