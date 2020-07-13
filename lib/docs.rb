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
require_relative 'docs/version'

module Docs
  autoload(:API, 'docs/api')
  autoload(:Banner, 'docs/banner')
  autoload(:CLI, 'docs/cli')
  autoload(:Config, 'docs/config')
  autoload(:Errors, 'docs/errors')
  autoload(:Records, 'docs/records')
  autoload(:Table, 'docs/table')
  autoload(:TsvRenderer, 'docs/tsv_renderer')

  module Commands
    autoload(:Documents, 'docs/commands/documents')
  end

  def self.configure_faraday(faraday)
    faraday.authorization :Bearer, Config::AccountConfig.new.auth_token
    faraday.headers[:user_agent] = "Flight-Docs/#{Docs::VERSION}"
  end

  def self.use_faraday_logger(faraday_or_connection)
    if ENV.fetch('DEBUG', false)
      faraday_or_connection.use(Faraday::Response::Logger, nil, {
        headers: false,
        bodies: false,
      }) do |l|
        l.filter(/(Authorization:)(.*)/, '\1 [REDACTED]')
      end
    end
  end
end
