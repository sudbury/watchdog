require 'slack-notifier'
require 'colorize'
require 'timeout'
require 'net/https'
require 'uri'
require 'active_support/hash_with_indifferent_access'
require 'open3'
require 'yaml'
require_relative 'lib/Checker/HTTPChecker.rb'
require_relative 'lib/Checker/SlackNotifier.rb'

options = YAML.load_file(File.dirname(__FILE__) + '/watchdog.yml').deep_symbolize_keys!

##########
# Script #
##########
notifier = SlackNotifier.new(webhook: options[:slack][:webhook])
f = File.open(options[:lock_file], File::RDWR | File::CREAT, 0644)

if Timeout.timeout(1) { f.flock(File::LOCK_NB | File::LOCK_EX) }
  checker = HTTPChecker.new

  fail_msg = options[:slack][:fail_msg] % { endpoint: options[:check][:endpoint] }

  options[:stages].each_with_index do |stage, stage_index|

    puts "Entering Stage #{stage_index+1} checks".blue

    if stage[:delay]
      puts "Sleeping for #{stage[:delay]} seconds per 'delay' directive in stage #{stage_index+1} config".blue
      sleep stage[:delay]
      puts 'Checker has woken'.green
    end

    if checker.check(options[:check][:endpoint], options[:check][:retries], options[:check][:options])
      puts "Status Checks Suceeded for #{options[:check][:endpoint]}".green
      break
    else
      puts "Stage #{stage_index+1} Status Checks Failed for #{options[:check][:endpoint]}".red

      notifier.send(fail_msg, 'danger')

      stage[:actions].map do |action|
        results = checker.exec(action)

        if results[2] == 0
          type = 'good'
        else
          if results[2].nil?
            results[2] = '127: command not found'
          end
          type = 'danger'
        end

        output = ''
        if results[0].nil? || results[0].strip.empty?
          output += "*No stdout*\n"
        else
          output += "Stdout:\n#{results[0].strip}\n"
        end

        if results[1].nil? || results[1].strip.empty?
          output += "*No stderr*"
        else
          output += "Stderr:\n#{results[1].strip}"
        end

        notifier.send "Took action: #{action} which ended with exit code #{results[2]}.\n#{output}", type
      end
    end
  end
else
  puts 'Lock could not be aquired'.red
end

f.close
