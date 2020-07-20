#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
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
# https://github.com/alces-flight/flight-account
#==============================================================================

require 'json_api_client'

module Docs
  module Records
    class BaseRecord < JsonApiClient::Resource
      self.site = Config::DocsConfig.new.base_url
    end

    BaseRecord.connection do |connection|
      API.configure_faraday(connection.faraday)
      API.use_faraday_logger(connection)
      connection.faraday.ssl.verify = Config::DocsConfig.new.verify_ssl?
    end

    class Document < BaseRecord
      attr_accessor :content

      def hashid
        @hashid ||= Docs.encode_id(id)
      end

      def content
        @content.to_s
      end

      def add_location(location)
        _locations << location
      end

      def locations
        _locations.join(", ")
      end

      def location
        if containers.empty?
          record.name
        else
          names = containers
            .map { |c| c.respond_to?(:display_id) ? "Case #{c.display_id}" : c.name }
          if names.length > 1
            names[1..-1].join(" / ")
          else
            names[0]
          end
        end
      end

      def content_type
        self['content-type'] || self['content_type']
      end

      private

      def _locations
        @_locations ||= [location]
      end
    end

    class Case < BaseRecord
      def display_id
        self['display-id'] || self['display_id']
      end
    end
    class Component < BaseRecord; end
    class Site < BaseRecord; end

    class Global < BaseRecord
      def name
        'Global'
      end
    end
  end
end
