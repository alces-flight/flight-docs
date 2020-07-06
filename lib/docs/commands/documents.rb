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
require_relative '../api'
require_relative '../banner'
require_relative '../table'
require_relative '../tsv_renderer'

require 'tty-markdown'
require 'tty-pager'
require 'whirly'
# require 'html2text'
# require 'tty-prompt'
# require 'word_wrap'

module Docs
  module Commands
    class Documents
      def list(args, options)
        Docs::Banner.emit
        documents = whirly Paint['Retrieving documents'] do
          api.list
        end

        table = Table.build do |t|
          headers 'ID', 'Title', 'Type'
          documents.each do |doc|
            row doc['id'], doc['title'], doc['content_type']
          end
        end

        if $stdout.tty?
          if documents.empty?
            puts "No documents found."
          else
            table.emit
          end
        else
          table.emit(renderer: Docs::TsvRenderer)
        end
      end

      def show(args, options)
        id = args.first
        doc = whirly Paint["Retrieving document #{id}"] do
          api.get(id.strip)
        end

        content =
          if $stdout.tty? && !options[:no_pretty] && doc['content_type'] == 'text/markdown'
            TTY::Markdown.parse(doc['content'])
          else
            doc['content']
          end

        if options[:no_pager]
          puts content
        else
          TTY::Pager.new.page(content)
        end
      end

      def download(args, options)
        id = args.first
        doc = whirly Paint["Downloading document #{id}"] do
          api.get(id.strip)
        end

        file = options[:output] || doc['title']
        File.write(file, doc['content'])
      end

      private

      def whirly(status, &block)
        if $stdout.tty?
          r = nil
          Whirly.start(
            spinner: 'star',
            remove_after_stop: true,
            append_newline: false,
            status: status,
          ) do
            r = block.call
          end
          r
        else
          block.call
        end
      end

      def api
        @api ||= Docs::FakeAPI.new
      end
    end
  end
end
