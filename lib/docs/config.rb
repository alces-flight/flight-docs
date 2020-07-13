#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Docs.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Docs is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Docs. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Docs, please visit:
# https://github.com/alces-flight/flight-docs
#==============================================================================
require 'xdg'
require 'yaml'
require 'fileutils'
require 'etc'

module Docs
  module Config
    class Base
      private

      def data
        @data ||= load
      end

      def load
        if File.exists?(config_file)
          YAML.load_file(config_file)
        else
          {}
        end
      end

      def config_file
        File.join(config_dir, 'config.yml')
      end

      def config_dir
        @xdg ||= XDG::Environment.new
        File.join(@xdg.config_home, subdirectory)
      end
    end

    class DocsConfig < Base
      def base_url
        ENV['flight_CENTER_URL'] ||
          data[:base_url] ||
          'http://center.alces-flight.lvh.me:3003/api/v2'
        # 'https://staging.documents.alces-flight.com/api/v2'
        # 'https://center.alces-flight.com/api/v2'
      end

      def verify_ssl?
        !!data[:verify_ssl]
      end

      def set(key, value)
        if value
          data[key.to_sym] = value
        else
          data.delete(key.to_sym)
        end
        save
      end

      def save
        unless Dir.exists?(config_dir)
          FileUtils.mkdir_p(config_dir, mode: 0700)
        end
        File.write(config_file, data.to_yaml)
      end

      private

      def subdirectory
        File.join('flight', 'docs')
      end
    end

    class AccountConfig < Base
      def auth_token
        data[:auth_token]
      end

      private

      def subdirectory
        File.join('flight', 'account')
      end
    end
  end
end
