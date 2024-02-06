# Returns the formatted date while running
def run_date
  Time.new.strftime('%Y-%m-%d')
end

# Returns the hostname of the system
# Defaults to "anon"
def hostname
  `hostname -s`.chomp.presence || 'anon'
end


# Runs a command in the system shell
# Does not run the command if $dry_run global variable is truthy
def run_cmd(cmd)
    if $dry_run
        puts "\n#{cmd}\n"
        return ""
    else
        `#{cmd}` 
    end   
end
