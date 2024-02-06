require 'google_drive'
require './helpers/shared'
# Uploads backup artifacts
def upload_afrtifact(artifact_path, artifact_name)
  $logger.info 'Uploading artifact to google drive'
  # Absolute path for the Service Accounts certificate
  account_key_path = File.join(Dir.getwd, 'certs', ENV['CERT_NAME'])

  # In case of dry run, only print info
  if $dry_run
    puts "\n Upload data: \n"
    puts "Cert path: #{account_key_path}"
    puts "Upload file: #{artifact_path}"
    puts "Upload name: #{artifact_name}"
    puts "Upload target: #{ENV['DRIVE_URL']}"
    return nil
  end

  raise 'Cannot find cert' unless File.exist?(account_key_path)

  # Create a GoogleDrive session
  session = GoogleDrive::Session.from_service_account_key(account_key_path)

  # Search for target folder
  target_folder = session.folder_by_url(ENV['DRIVE_URL'])
  $logger.info 'Found target folder'

  # Upload file to root collection
  remote_file = session.upload_from_file(artifact_path, artifact_name, convert: false)
  $logger.info 'Uploaded artifact to root collection'

  # Copy file to the target fodler
  target_folder.add remote_file
  $logger.info 'Artifact moved to target folder'

  # Remove temp file from root collection
  session.root_collection.remove remote_file
  $logger.info 'Artifact removed from root collection'
end

# Instead of google drive, saves backup locally
def local_save(artifact_path, artifact_name)
  run_cmd "cp #{artifact_path} #{File.join(Dir.getwd, artifact_name)}"
  $logger.info 'Artifact moved to root folder'
end
