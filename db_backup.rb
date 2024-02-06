#!/usr/bin/env ruby
#
require './helpers/docker'
require './helpers/files'
require './helpers/upload'
require 'dotenv/load'
require 'arg-parser'

class DbSafe

  include ArgParser::DSL

  purpose <<-EOT
      This is an automated program, that detects all postgresql databases 
      and saves a backup for each to a google drive folder.
  EOT

  flag_arg :dry, 'Dry run. Prints out all the commands that will be executed, without affecting the filesystem'
  flag_arg :local, 'Only save backup locally, instad of google drive'

  def perform_backup(local)

    # Check for missing Env variables
    raise "Drive url is missing" unless ENV["DRIVE_URL"].present? || local
    raise "Cert name is missing" unless ENV["CERT_NAME"].present? || local
    
    
    # get all running postgres containers, and filter out the ignored ones
    db_containers = active_containers
                    .filter { |container| container[:image].match?(/postgres/) }
                    .filter { |container| !ignored_containers.include? container[:name] }
    
    # Create individual backup dumps in the workfolder
    backups = db_containers.map { |c| backup_container(c) }.compact
    
    # The final zip name is created from the hostname e.g Lois and creation date
    artifact_name = "#{hostname}-#{run_date}.zip"
    
    # Zip all the backups together
    artifact_path = zip_files(backups, artifact_name)
    
    # Upload artifact to Google Drive or local fodler
  
    upload_afrtifact(artifact_path, artifact_name) unless local
    local_save(artifact_path,artifact_name) if local

    clean_work_folder
    
  end

  def run
      if opts = parse_arguments
         $dry_run = opts.dry.present?
        perform_backup opts.local.present?
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
