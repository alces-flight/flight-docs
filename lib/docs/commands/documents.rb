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
require_relative '../patches/kramdown'
require 'tty-pager'
require 'whirly'

module Docs
  module Commands
    class Documents
      def list(args, options)
        Docs::Banner.emit
        documents = whirly Paint['Retrieving documents'] do
          api.list
        end

        pretty_content_type = self.method(:pretty_content_type)
        table = Table.build do |t|
          headers 'ID', 'Location', 'Title', 'Type'
          documents.each do |doc|
            row doc.id, doc.location, doc.filename, pretty_content_type.(doc.content_type)
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

      def show(id, options)
        doc = whirly Paint["Retrieving document #{id}"] do
          api.get(id)
        end

        content =
          if $stdout.tty? && !options[:no_pretty] && doc.content_type == 'text/markdown'
            TTY::Markdown.parse(doc.content)
          else
            doc.content
          end

        if options[:no_pager]
          puts content
        else
          TTY::Pager.new.page(content)
        end
      end

      def download(args, options)
        id = args.first.strip
        doc = whirly Paint["Downloading document #{id}"] do
          api.get(id)
        end

        file = options[:output] || doc.filename
        File.write(file, doc.content)
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
        @api ||= Docs::API.new
      end

      def pretty_content_type(content_type)
        case content_type
        when "image/png", "image/jpg", "image/jpeg"
          "Image"
        when "application/pdf"
          "PDF"
        when 'application/zip',
          'application/x-bzip2',
          'application/x-bzip',
          'application/x-gzip'
          'Archive'
        when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'application/vnd.oasis.opendocument.spreadsheet',
          'application/vnd.ms-excel'
          'Spreadsheet'
        when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.oasis.opendocument.text',
          'application/msword'
          'Word document'
        when 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'application/vnd.oasis.opendocument.presentation',
          'application/vnd.ms-powerpoint'
          'Presentation'
        when 'text/markdown'
          'Markdown'
        when 'text/plain', /^text\//
          'Text'
        else
          "Unknown"
        end
      end
    end
  end
end
