require 'json'
require 'active_support/all'
require './helpers/shared'

def active_containers
  format = '{"id":"{{ .ID }}", "image": "{{ .Image }}", "name":"{{ .Names }}"}'

  json_str = `docker ps --format='#{format}' | jq --slurp`

  JSON.parse(json_str).map(&:symbolize_keys)
end

def container_root_user_name(container)
  user_env = `docker exec #{container[:name]} bash -c 'echo $POSTGRES_USER'`.chomp
  user_env.presence || 'postgres'
end

def backup_container(container)
  backup_name = "#{container[:name]}-#{run_date}.sql"

  backup_path = "/tmp/#{backup_name}"

  root_user = container_root_user_name container

  backup_command = "pg_dumpall -U #{root_user} > #{backup_path}"

  result = `docker exec #{container[:name]} bash -c '#{backup_command}'`

  # if result is empty then no error was present
  return nil unless result.empty?

  # copy backup from container
  `docker cp #{container[:name]}:#{backup_path} #{work_folder}`

  File.join(work_folder, backup_name)
end
