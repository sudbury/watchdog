# Watchdog #

![Watchdog](http://ehurtig.com/bulldog-20clipart-bulldog-clip-art-14.gif)

Monitors and takes corrective action to fix broken web services.  Integrates with slack.

> Also check out bluepill for this kind of corrective action monitoring.

WARNING: This is very much an alpha-stage piece of software

## Requirements ##

Watchdog requires a simple ruby environment with the `ruby`, `gem`, and `bundle` commands available.  This can be done by installing ruby with `apt-get` or, if you want to have more control, [rbenv](https://github.com/sstephenson/rbenv)

## Installing ##

* Install git, ruby, and bundler. On Ubuntu its as easy as `sudo apt-get install git ruby bundler`
* `git clone https://bitbucket.org/sudbury/watchdog /opt/watchdog`
* Add this: `* * * * * ruby /opt/watchdog/watchdog.rb` to your crontab using `crontab -e` or by creating a system crontab
* change to the install dir `cd /opt/watchdog` and run `bundle install`

And you're done!

## Configuration

There is a starter config file provided: `watchdog.yml`

```yaml
check:
  # The endpoint to check
  endpoint: https://localhost/
  # The number of retries before marking it as failed
  retries: 3
  # some http options
  options:
    use_ssl: true
    verify_mode: 0 # Probably need this as your cert wont be valid for localhost
    headers:
      - Host: yourdomain.com
slack:
  # Make a generic incomming webhook
  webhook: https://hooks.slack.com/services/..............
  fail_msg: Watchdog has detected failure on the endpoint %{endpoint}
stages:
   - actions:
      # A list of shell commands to execute, in order, when a failure is detected
       - service hhvm restart
   - delay: 60
     actions:
      - reboot
lock_file: /tmp/watchdog.lock
```

## Example output

Example of successful, normal operation

```
○ → checker
Entering Stage 1 checks
Status Checks Suceeded for https://localhost/
```

Example output of complete failure that entered stage 2 and rebooted the server

```
Entering Stage 1 checks
Status check attempt 1 of 3 failed on https://localhost/
Status check attempt 2 of 3 failed on https://localhost/
Status check attempt 3 of 3 failed on https://localhost/
Stage 1 Status Checks Failed for https://localhost/
Pining Slack with message Watchdog has detected failure on endpoint https://localhost/
Running action command service hhvm restart
  * Completed action command service hhvm restart
Pining Slack with message Took action: service hhvm restart which ended with exit code pid 31451 exit 0.
Stdout:
hhvm start/running, process 31461
Stderr:
stop: Unknown instance:
Entering Stage 2 checks
Sleeping for 60 seconds per 'delay' directive in stage 2 config
Checker has woken
Status check attempt 1 of 3 failed on https://localhost/
Status check attempt 2 of 3 failed on https://localhost/
Status check attempt 3 of 3 failed on https://localhost/
Stage 2 Status Checks Failed for https://localhost/
Pining Slack with message Watchdog has detected failure on svr-nginx-01 endpoint https://localhost/
Running action command sleep 10 && reboot &
  * Completed action command sleep 10 && reboot &
Pining Slack with message Took action: sleep 10 && reboot & which ended with exit code pid 4843 exit 0.
*No stdout*
*No stderr*

Broadcast message from root@server
	(unknown) at 12:31 ...

The system is going down for reboot NOW!
```

WARNING: Be careful with your actions.  If you have a reboot action make sure there is a long delay (60 seconds)
because you might find yourself in an infinite reboot cycle otherwise.

## Contact and Contributing ##

* Eddie Hurtig <hurtige@sudbury.ma.us>
