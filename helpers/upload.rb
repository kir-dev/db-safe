require 'google_drive'

def upload_afrtifact(artifact_path, artifact_name)
  account_key_path = File.join(Dir.getwd, 'certs', 'config.json')

  return nil unless File.exist?(account_key_path)

  session = GoogleDrive::Session.from_service_account_key(account_key_path)

  target_folder = session.folder_by_url('https://drive.google.com/drive/folders/1bHZuSKnDWzP_LWC6QZ-iURXdXIsFrpU4?usp=sharing')

  remote_file = session.upload_from_file(artifact_path, artifact_name, convert: false)

  target_folder.add remote_file

  session.root_collection.remove remote_file
end
