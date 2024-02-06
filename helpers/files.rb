require 'fileutils'
require './helpers/shared'

# Gets the names of the ignored containers from the .dbignore file
def ignored_containers
  ignore_file_path = File.join(Dir.getwd, '.dbignore')

  return [] unless File.exist?(ignore_file_path)

  File.readlines(ignore_file_path).map(&:chomp)
end

# Creates a temporary work folder and returns its absolue path
def work_folder
  path = File.join(Dir.getwd, 'tmp', run_date)

  FileUtils.mkdir_p path unless File.directory? path || $dry_run

  path
end

# Deletes all temporary files to save space
def clean_work_folder
  FileUtils.remove_dir work_folder unless $dry_run
end

# Zips together multiple backups, into a single file
# Returns the absolute path of the resulting artifact
def zip_files(paths, output)
  out_path = File.join(work_folder, output)
  
  run_cmd "zip -uj #{out_path} #{paths.join(' ')}"

  out_path
end
