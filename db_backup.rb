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
  

  def perform_backup
    raise "Drive url is missing" unless ENV["DRIVE_URL"].present?
    raise "Cert name is missing" unless ENV["CERT_NAME"].present?
    
    
    # get all running postgres containers, and filter ignored ones
    db_containers = active_containers
                    .filter { |container| container[:image].match?(/postgres/) }
                    .filter { |container| !ignored_containers.include? container[:name] }
    
    backups = db_containers.map { |c| backup_container(c) }.compact
    
    artifact_name = "#{hostname}-#{run_date}.zip"
    
    artifact_path = zip_files(backups, artifact_name)
    
    upload_afrtifact(artifact_path, artifact_name)
    
    clean_work_folder
    
  end

  def run
      if opts = parse_arguments
         $dry_run = opts.dry.present?
        perform_backup
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
