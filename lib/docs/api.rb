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
# https://github.com/alces-flight/flight-account
#==============================================================================

require_relative 'records'
require_relative 'errors'

module Docs
  class API
    def list
      Document.all
    rescue JsonApiClient::Errors::ConnectionError
      raise ApiUnavailable
    end

    def get(id)
      begin
        doc = parse(id).is_a?(Integer) ? get_by_id(id) : get_by_filename(id)
      rescue JsonApiClient::Errors::NotFound
        raise DocNotFound, id
      else
        begin
          response = http.get(doc.links.download)
        rescue Faraday::ResourceNotFound
          raise DocContentNotFound, id
        else
          doc.content = response.body
        end
        doc
      end
    rescue JsonApiClient::Errors::ConnectionError, Faraday::ConnectionFailed
      raise ApiUnavailable
    end

    private

    def get_by_id(id)
      Document.find(id).first
    end

    def get_by_filename(filename)
      docs = Document.where(filename: filename).all
      if docs.empty?
        raise DocNotFound, filename
      elsif docs.length > 1
        raise MultipleDocsFound.new(filename, docs)
      else
        docs.first
      end
    end

    def parse(id)
      begin
        Integer(id)
      rescue ArgumentError
        id
      end
    end

    def http
      @http ||= Faraday.new do |faraday|
        Docs.configure_faraday(faraday)
        Docs.use_faraday_logger(faraday)
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.use Faraday::Response::RaiseError
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
