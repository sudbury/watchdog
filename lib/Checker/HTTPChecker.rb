###########
# Classes #
###########
class HTTPChecker
  def check(url, retries, options = {})
    retries.times do |attempt|
      return true if sucess?(request(url, options))
      puts "Status check attempt #{attempt + 1} of #{retries} failed on #{url}"
      sleep 1
    end
    false
  end

  def request(url, options = {})

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = options[:use_ssl] if options[:use_ssl]
    http.verify_mode = options[:verify_mode] if options[:verify_mode]

    case options[:method] or 'GET'
    when 'GET'
      request = Net::HTTP::Get.new(url)
    when 'POST'
      request = Net::HTTP::Post.new(url)
    when 'PUT'
      request = Net::HTTP::Put.new(url)
    when 'DELETE'
      request = Net::HTTP::Delete.new(url)
    when 'OPTIONS'
      request = Net::HTTP::Options.new(url)
    else
      raise "Method #{options[:method]} is not supported"
    end

    options[:headers].each do |hash|
      hash.each do |header, value|
        request[header.to_s] = value
      end
    end if options[:headers]

    begin
      http.request(request)
    rescue Exception => e
      return false
    end
  end

  def sucess?(response)
    response.is_a?(Net::HTTPResponse) && response.code.to_i < 400 && response.body.include?('OK')
  end

  def exec(cmd)
    begin
      puts "Running action command #{cmd}"
      stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)

      out = stdout.gets(nil)
      err = stderr.gets(nil)
      stdout.close
      stderr.close
      exit_code = wait_thr.value
      puts "  * Completed action command #{cmd}".green
    rescue StandardError => ex
      puts "  * #{ex.message}".red
    end

    [out, err, exit_code]
  end
end
