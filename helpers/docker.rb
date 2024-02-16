require 'json'
require 'active_support/all'
require './helpers/shared'

# Returns all active docker containers in a hash array
# Each entry has :id, :name, :image
def active_containers
  format = '{"id":"{{ .ID }}", "image": "{{ .Image }}", "name":"{{ .Names }}"}'

  json_str = `docker ps --format='#{format}' | jq --slurp`

  $logger.info 'Getting active containers'

  hash = JSON.parse(json_str).map(&:symbolize_keys)

  names = hash.map { |h| h[:name] }
  $logger.info "Current active containers are: #{names.to_json}"

  hash
end

def available_volumes
  json_str = `docker volume ls --format='json' | jq --slurp`

  hash = JSON.parse(json_str).map{|h| h.transform_keys(&:downcase).symbolize_keys}

  names = hash.map { |h| h[:name] }
  $logger.info("Avalable volumes are: #{names.to_json}")

  hash
end

# Gets the postgresql user from the containers ENV
# Defaults to postgres if its not set
def container_root_user_name(container)
  $logger.info "Getting postgres password for '#{container[:name]}'"

  user_env_cmd = "docker exec #{container[:name]} bash -c 'echo $POSTGRES_USER'"
  $logger.info "Executing `#{user_env_cmd}`"

  user_env = `#{user_env_cmd}`.chomp
  $logger.info "got_user_env:#{user_env}"

  # return user env or default 'postgres'
  user_env.presence || 'postgres'
end

# Creates a full database dump and saves it in a temporary work folder
# Returns the absolute path of the created backup
def backup_container(container)
  $logger.info "Backing up #{container[:name]}"

  # The backup name is <container_name>-<date>.sql
  backup_name = "#{container[:name]}-#{run_date}.sql"

  backup_path = File.join(work_folder, backup_name)

  # This is used in PG_DUMP as a username
  root_user = container_root_user_name container

  backup_command = "pg_dumpall -U #{root_user}"

  result = run_cmd "docker exec #{container[:name]} bash -c '#{backup_command}' > #{backup_path}"

  # if result is empty then no error was present
  unless result.empty?
    $info.error "Could not backup #{container[:name]}"
    $info.error result
    return nil
  end

  # Return absolute path of backup
  backup_path
end


def check_docker_image

  $logger.info "Checking docker image status"

  res = `docker image inspect kirdev/volumesafe`

  if $?.exitstatus != 0
    # Image not found
    $logger.info "Docker image not found"
    $logger.info `docker image build -t kirdev/volumesafe .`
  end

end



def backup_volume(volume)
  $logger.info "Backing up #{volume[:name]}"

  # The backup name is <container_name>-<date>.sql
  backup_name = "volume_#{volume[:name]}-#{run_date}.zip"

  backup_path = File.join(work_folder, backup_name)

  backup_command = "zip -rq - /backup/* | base64"

  receive_command = "base64 --decode > #{backup_path}"

  result = run_cmd "docker run --rm -v #{volume[:name]}:/backup kirdev/volumesafe bash -c '#{backup_command}' | #{receive_command} "

  # if result is empty then no error was present
  unless result.empty?
    $info.error "Could not backup #{container[:name]}"
    $info.error result
    return nil
  end

  backup_path
end
