#!/usr/bin/env ruby
#
require './helpers/docker'
require './helpers/files'
require './helpers/upload'
require 'dotenv/load'


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
