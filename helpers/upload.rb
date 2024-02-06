require 'google_drive'

def upload_afrtifact(artifact_path, artifact_name)
  
  account_key_path = File.join(Dir.getwd, 'certs', ENV["CERT_NAME"])

  if $dry_run
    puts "\n Upload data: \n"
    puts "Cert path: #{account_key_path}"
    puts "Upload file: #{artifact_path}"
    puts "Upload name: #{artifact_name}"
    puts "Upload target: #{ENV["DRIVE_URL"]}"
    return nil
  end




  raise 'Cannot find cert' unless File.exist?(account_key_path)

  session = GoogleDrive::Session.from_service_account_key(account_key_path)

  target_folder = session.folder_by_url(ENV["DRIVE_URL"])

  remote_file = session.upload_from_file(artifact_path, artifact_name, convert: false)

  target_folder.add remote_file

  session.root_collection.remove remote_file
end
