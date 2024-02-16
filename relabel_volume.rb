#!/usr/bin/env ruby
#

require 'dotenv/load'
require 'arg-parser'
require 'logger'
require 'json'
require 'securerandom'
require './helpers/docker'
require './helpers/shared'


class VolumeRelabel
  include ArgParser::DSL

  purpose <<-EOT
      This program creates a temp copy of a volume, and recreates it with the specified labels
  EOT

  positional_arg :volume, 'The volume to relabel'

  flag_arg :dry, 'Dry run. Prints out all the commands that will be executed, without affecting the filesystem'


  rest_arg :labels, 'The labels to add to volume'


  def run
    if opts = parse_arguments
      begin
        $logger = Logger.new(STDOUT)
        $logger.info 'Starting program}'
        $logger.info "Options: #{opts.to_json}"

        $dry_run = opts.dry.present?

        check_docker_image

        temp_volume = SecureRandom.uuid
        $logger.info "Temp volume is #{temp_volume}"

        $logger.info run_cmd "docker volume create #{temp_volume}"

        $logger.info run_cmd "docker run --rm -it -v #{opts.volume}:/original -v #{temp_volume}:/backup bash -c 'cp -r /original/. /backup/.'"

        $logger.info run_cmd "docker volume rm #{opts.volume}"

        labels = opts.labels || []
        label_tags = labels.map{|l| "--label='#{l}'"}.join(' ')

        $logger.info run_cmd "docker volume create #{opts.volume} #{label_tags}"

        $logger.info run_cmd "docker run --rm -it -v #{opts.volume}:/original -v #{temp_volume}:/backup bash -c 'cp -r /backup/. /original/.'"

        $logger.info run_cmd "docker volume rm #{temp_volume}"


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

VolumeRelabel.new.run
