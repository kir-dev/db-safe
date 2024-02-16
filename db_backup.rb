#!/usr/bin/env ruby
#

require 'dotenv/load'
require 'arg-parser'
require 'logger'

require './helpers/docker'
require './helpers/files'
require './helpers/upload'

$logger = Logger.new('logs/dbsafe.log')

class DbSafe
  include ArgParser::DSL

  purpose <<-EOT
      This is an automated program, that detects all postgresql databases#{' '}
      and saves a backup for each to a google drive folder.
  EOT

  flag_arg :dry, 'Dry run. Prints out all the commands that will be executed, without affecting the filesystem'
  flag_arg :local, 'Only save backup locally, instad of google drive'

  flag_arg :verbose, 'Prints out logs instead of logfile'

  def perform_backup(local)
    $logger.info 'Started performing automatic backup'
    # Check for missing Env variables
    raise 'Drive url is missing' unless ENV['DRIVE_URL'].present? || local
    raise 'Cert name is missing' unless ENV['CERT_NAME'].present? || local

    check_docker_image


    # get all running postgres containers, and filter out the ignored ones
    db_containers = active_containers
                    .filter { |container| container[:image].match?(/postgres/) }
                    .filter { |container| !ignored_containers.include? container[:name] }

    # Create individual backup dumps in the workfolder
    db_backups = db_containers.map { |c| backup_container(c) }.compact
    $logger.info "db_backups: #{db_backups}"

    # perform full volume backups
    volumes = available_volumes.filter { |v| v[:labels].split(',').include? 'hu.kirdev.dbsafe=' }

    # Create individual volume backups

    volume_backups = volumes.map { |v| backup_volume(v) }.compact
    $logger.info "volume_backups: #{volume_backups}"

    # The final zip name is created from the hostname e.g Lois and creation date
    artifact_name = "#{hostname}-#{run_date}.zip"

    backups = db_backups | volume_backups

    # Zip all the backups together
    artifact_path = zip_files(backups, artifact_name)

    # Upload artifact to Google Drive or local fodler

    upload_afrtifact(artifact_path, artifact_name) unless local
    local_save(artifact_path, artifact_name) if local

    clean_work_folder
  end

  def run
    if opts = parse_arguments
      begin
        $logger = Logger.new(STDOUT) if opts.verbose.present?
        $logger.info 'Starting program}'
        $logger.info "Options: #{opts.to_json}"

        # Set dry run flag from options
        $dry_run = opts.dry.present?

        # Start backup
        perform_backup opts.local.present?
        $logger.info 'Program ended with success'
      rescue Exception => e
        $logger.error e
      end
    else
      # False is returned if argument parsing was not completed
      # This may be due to an error or because the help command
      # was used (by specifying --help or /?). The #show_help?
      # method returns true if help was requested, otherwise if
      # a parse error was encountered, #show_usage? is true and
      # parse errors are in #parse_errors
      show_help? ? show_help : show_usage
    end
  end
end

DbSafe.new.run
