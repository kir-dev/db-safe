#!/usr/bin/env ruby
#
require './helpers/docker'
require './helpers/files'
require './helpers/upload'

# get all running postgres containers, and filter ignored ones
db_containers = active_containers
                .filter { |container| container[:image].match?(/postgres/) }
                .filter { |container| !ignored_containers.include? container[:name] }

backups = db_containers.map { |c| backup_container(c) }.compact

artifact_name = "#{hostname}-#{run_date}.zip"

artifact_path = zip_files(backups, artifact_name)

upload_afrtifact(artifact_path, artifact_name)

clean_work_folder
