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
require 'commander'

module Docs
  class CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME', 'docs')

    extend Commander::CLI

    program :application, Docs::TITLE
    program :name, PROGRAM_NAME
    program :version, "v#{Docs::VERSION}"
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
    alias_command :ls, :list

    command :show do |c|
      cli_syntax(c, 'NAME|QUICK_CODE')
      c.summary = 'Display a document.'
      c.description = 'Display a document in your terminal.'
      c.slop.bool '--no-pager', 'Do not use a pager to view the document.', default: false
      c.slop.bool '--no-pretty', 'Disable pretty rendering of the document.', default: false
      c.action do |args, opts, config|
        id = args.first.strip
        if id.empty?
          raise Commander::Command::CommandUsageError, "DOCUMENT cannot be blank"
        end
        Docs::Commands::Documents.new.show(id, opts)
      end
    end

    command :download do |c|
      cli_syntax(c, 'NAME|QUICK_CODE')
      c.summary = 'Download a document.'
      c.description = 'Download DOCUMENT.'
      c.slop.string '-o', '--output', 'Save the document to FILE.  Defaults to the name of the document.', meta: 'FILE'
      c.action run_docs_method(:download)
    end
    alias_command :get, :download
  end
end
