def run_date
  Time.new.strftime('%Y-%m-%d')
end

def hostname
  `hostname -s`.chomp.presence || 'anon'
end
