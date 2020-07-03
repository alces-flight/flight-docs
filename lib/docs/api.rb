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

require_relative 'config'
require_relative 'errors'
require_relative 'version'

require 'http'
require 'json'

module Docs
  class API
    def list
      base_url = Config.base_url.chomp('/')

      response = http.post(
        "#{base_url}/documents",
      )

      if !response.status.success?
        data = (JSON.parse(response) rescue {})
        if data.key?('error')
          raise DocsError, data['error']
        else
          raise DocsError, response.to_s
        end
      else
        JSON.parse(response.to_s)['data']
      end
    end

    def get
      raise NotImplementedError
    end

    private

    def http
      h = HTTP.headers(
        user_agent: "Flight-Docs/#{Docs::VERSION}",
        accept: 'application/json'
      )
      #        if Config.auth_token
      #          h.auth("Bearer #{Config.auth_token}")
      #        else
      h
      #        end
    end
  end

  class FakeAPI
    def list
      sleep 2
      fake_documents
    end

    def get(id)
      sleep 1
      doc = fake_documents.detect { |d| d['title'] == id || d['id'].to_s == id }
      if doc.nil?
        raise DocNotFound, id
      else
        doc
      end
    end

    private

    def fake_documents
      [
        'User account password change',
        'Data analysis exercise',
        'Cheese and wine',
      ].each_with_index.map do |name, idx|
        fake_document(name, idx)
      end
    end

    def fake_document(name, idx)
      {
        'id' => idx,
        'title' => "#{name}",
        'content_type' => 'text/markdown',
        'content' => <<~EOF
          # #{name} title

          This is some introductory text about #{name}.

          Reasons that #{name} is very good.

          1. It's good.
          2. It's very good.
          3. It's better than that.
          4. Read [more reasons](http://example.com)

          ## Lorems

          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
          ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
          aliquip ex ea commodo consequat.  Duis aute irure dolor in
          reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
          pariatur.
        EOF
      }
    end
  end
end
