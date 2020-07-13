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
require 'tty-markdown'
require_relative '../patches/kramdown'
require 'tty-pager'
require 'whirly'

module Docs
  module Commands
    class Documents

      def list(args, options)
        Docs::Banner.emit
        asset_signed_in

        documents = whirly Paint['Retrieving documents'] do
          api.list
        end

        pretty_content_type = self.method(:pretty_content_type)
        location_cols, title_cols = truncate_lengths(documents)

        table = Table.build do |t|
          headers 'ID', 'Location', 'Title', 'Type'
          documents.each do |doc|
            if $stdout.tty?
              # NOTE: If changing this also change `truncate_lengths`.
              row(
                doc.id,
                doc.location.truncate(location_cols),
                doc.filename.truncate(title_cols),
                pretty_content_type.(doc.content_type)
              )
            else
              row(
                doc.id,
                doc.location,
                doc.filename,
                pretty_content_type.(doc.content_type)
              )
            end
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
        asset_signed_in

        doc = whirly Paint["Retrieving document #{id}"] do
          api.get(id)
        end

        if printable?(doc)
          content = pretty_content(doc, pretty: !options[:no_pretty])
          if options[:no_pager]
            puts content
          else
            TTY::Pager.new.page(content)
          end
        else
          save(doc, output: options[:output])
        end
      end

      def download(args, options)
        asset_signed_in

        id = args.first.strip
        doc = whirly Paint["Downloading document #{id}"] do
          api.get(id)
        end
        save(doc, output: options[:output])
      end

      private

      def asset_signed_in
        raise Errors::NotSignedIn unless Config::AccountConfig.new.signed_in?
      end

      def save(doc, output:)
        filename = output || doc.filename
        puts("Saving binary file to #{filename.inspect}")
        File.write(filename, doc.content)
      end

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

      def printable?(doc)
        return true if !$stdout.tty?
        case doc.content_type
        when /^text\//
          true
        else
          false
        end
      end

      def pretty_content(doc, pretty:)
        if $stdout.tty? && pretty && doc.content_type == 'text/markdown'
          TTY::Markdown.parse(doc.content) rescue doc.content
        else
          doc.content
        end
      end

      def pretty_content_type(content_type)
        # NOTE: If changing this method also change `truncate_lengths`.
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

      # Return sensible lengths to which location and filename can be
      # truncated to avoid wrapping.
      #
      # The current algorithm can result in unnecessarily truncated locations.
      def truncate_lengths(documents)
        max_location_length = documents.map { |d| d.location.length }.max
        max_filename_length = documents.map { |d| d.filename.length }.max

        # We make a few assumptions here.
        #  - 3 cols is sufficient to display the id.
        #  - 11 cols is sufficient to display the content type.  The longest
        #    we currently have is `Spreadsheet`.
        #  - There are 4 columns.
        id_width = 3
        type_width = 11
        num_cols = 4
        padding = num_cols * 3 + 1

        # The available cols to split between location and filename
        available_cols = TTY::Screen.width - id_width - type_width - padding

        if max_location_length + max_filename_length <= available_cols
          # No truncation necessary.
          [ max_location_length, max_location_length ]
        else
          # Let's give 30% to location unless it needs less.
          location_cols = [available_cols * 0.3, max_location_length].min.to_i

          # The title gets everything else. Even if it doesn't need this much.
          title_cols = available_cols - location_cols

          [ location_cols, title_cols ]
        end
      end
    end
  end
end
