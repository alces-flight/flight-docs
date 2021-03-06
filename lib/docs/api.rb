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

require 'json_api_client'

module Docs
  class API

    def self.configure_faraday(faraday, auth_header: true)
      if auth_header
        faraday.authorization :Bearer, Config::AccountConfig.new.auth_token
      end
      faraday.headers[:user_agent] = "Flight-Docs/#{Docs::VERSION}"
    end

    def self.use_faraday_logger(faraday_or_connection)
      if ENV.fetch('DEBUG', false)
        faraday_or_connection.use(Faraday::Response::Logger, nil, {
          headers: true,
          bodies: false,
        }) do |l|
          l.filter(/(Authorization:)(.*)/, '\1 [REDACTED]')
        end
      end
    end

    def list
      query = Records::Document
        .includes(:containers, :record)
        .select(cases: 'display_id', components: 'name', sites: 'name')
      if block_given?
        query = yield query
      end
      funky_coalesce(query.all)
        .sort_by { |d| d.filename.downcase }
    rescue JsonApiClient::Errors::ConnectionError
      raise Errors::ApiUnavailable
    end

    def get(id_or_name)
      begin
        id = Docs.decode_id(id_or_name)
        doc = id ? get_by_id(id) : get_by_filename(id_or_name)
      rescue JsonApiClient::Errors::NotFound, JsonApiClient::Errors::AccessDenied
        raise Errors::DocNotFound, id
      else
        begin
          response = http.get(doc.links.download)
        rescue Faraday::ResourceNotFound
          raise Errors::DocContentNotFound, id
        else
          doc.content = response.body
        end
        doc
      end
    rescue JsonApiClient::Errors::ConnectionError, Faraday::ConnectionFailed
      raise Errors::ApiUnavailable
    end

    private

    def funky_coalesce(docs)
      by_download_link = docs.reduce({}) do |accum, doc|
        accum[doc.links.download] ||= []
        accum[doc.links.download] << doc
        accum
      end
      by_download_link.reduce([]) do |accum, link_and_docs|
        doc, *others = link_and_docs.second
        others.each do |d|
          doc.add_location(d.location)
        end
        accum << doc
        accum
      end
    end

    def get_by_id(id)
      Records::Document.find(id).first
    end

    def get_by_filename(filename)
      docs = list do |query|
        query.where(filename: filename)
      end
      if docs.empty?
        raise Errors::DocNotFound, filename
      elsif docs.length > 1
        raise Errors::MultipleDocsFound.new(filename, docs)
      else
        docs.first
      end
    end

    def http
      @http ||= Faraday.new do |faraday|
        self.class.configure_faraday(faraday, auth_header: false)
        self.class.use_faraday_logger(faraday)
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.use Faraday::Response::RaiseError
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
