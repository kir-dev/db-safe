require 'fileutils'
require './helpers/shared'

# Gets the names of the ignored containers from the .dbignore file
def ignored_containers
  ignore_file_path = File.join(Dir.getwd, '.dbignore')

  return [] unless File.exist?(ignore_file_path)

  ignored = File.readlines(ignore_file_path).map(&:chomp)

  $logger.info "Reading ignored containers: #{ignored}"

  ignored
end

# Creates a temporary work folder and returns its absolue path
def work_folder
  path = File.join(Dir.getwd, 'tmp', run_date)

  FileUtils.mkdir_p path unless File.directory? path || $dry_run

  path
end

# Deletes all temporary files to save space
def clean_work_folder
  $logger.info 'Cleaning up work folder'
  FileUtils.remove_dir work_folder unless $dry_run
end

# Zips together multiple backups, into a single file
# Returns the absolute path of the resulting artifact
def zip_files(paths, output)
  $logger.info "zipping files: #{paths.join(' ')}"

  out_path = File.join(work_folder, output)
  $logger.info "ZIP Output file: #{out_path}"
  run_cmd "zip -uj #{out_path} #{paths.join(' ')}"

  out_path
end
