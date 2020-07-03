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
# https://github.com/alces-flight/flight-docs
#==============================================================================
require_relative 'commands/documents'
require_relative 'version'

require 'commander'

module Docs
  class CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME', 'docs')

    extend Commander::CLI

    program :application, Docs::TITLE
    program :name, PROGRAM_NAME
    program :version, Docs::VERSION
    program :description, 'Alces Flight Center document viewer.'
    program :help_paging, false
    default_command :help

    class << self
      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end

      def run_docs_method(m)
        Proc.new do |args, opts, config|
          Docs::Commands::Documents.new.send(m, args, opts)
        end
      end
    end

    command :list do |c|
      cli_syntax(c)
      c.summary = 'List available documents.'
      c.description = 'List all available documents for your Alces Flight Center account.'
      c.action run_docs_method(:list)
    end

    command :show do |c|
      cli_syntax(c, 'DOCUMENT')
      c.summary = 'Display a document.'
      c.description = 'Display DOCUMENT in your terminal.'
      c.slop.bool '--no-pager', 'View the document in a pager', default: false
      c.slop.bool '--no-pretty', 'Display a pretty rendering of the document', default: false
      c.action run_docs_method(:show)
    end

    command :download do |c|
      cli_syntax(c, 'DOCUMENT')
      c.summary = 'Dowload a document.'
      c.description = 'Download DOCUMENT.'
      c.slop.string '-o', '--output', 'Save DOCUMENT to FILE.  Defaults to a file named DOCUMENT.', meta: 'FILE'
      c.action run_docs_method(:download)
    end
  end
end
