require 'json'
require 'active_support/all'
require './helpers/shared'

# Returns all active docker containers in a hash array
# Each entry has :id, :name, :image
def active_containers
  format = '{"id":"{{ .ID }}", "image": "{{ .Image }}", "name":"{{ .Names }}"}'

  json_str = `docker ps --format='#{format}' | jq --slurp`

  JSON.parse(json_str).map(&:symbolize_keys)
end

# Gets the postgresql user from the containers ENV
# Defaults to postgres if its not set
def container_root_user_name(container)
  user_env = `docker exec #{container[:name]} bash -c 'echo $POSTGRES_USER'`.chomp
  user_env.presence || 'postgres'
end

# Creates a full database dump and saves it in a temporary work folder
# Returns the absolute path of the created backup
def backup_container(container)

  # The backup name is <container_name>-<date>.sql
  backup_name = "#{container[:name]}-#{run_date}.sql"

  # The backup path inside the container
  backup_path = "/tmp/#{backup_name}"

  # This is used in PG_DUMP as a username
  root_user = container_root_user_name container

  backup_command = "pg_dumpall -U #{root_user} > #{backup_path}"

  result = run_cmd "docker exec #{container[:name]} bash -c '#{backup_command}'"

  # if result is empty then no error was present
  return nil unless result.empty?

  # Copy backup from container
  run_cmd "docker cp #{container[:name]}:#{backup_path} #{work_folder}"

  # Return absolute path of backup
  File.join(work_folder, backup_name)
end
