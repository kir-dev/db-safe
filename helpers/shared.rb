def run_date
  Time.new.strftime('%Y-%m-%d')
end

def hostname
  `hostname -s`.chomp.presence || 'anon'
end


def run_cmd(cmd)
    if $dry_run
        puts "\n#{cmd}\n"
        return ""
    else
        `#{cmd}` 
    end   
end
