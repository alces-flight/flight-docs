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
        assert_signed_in
        documents = whirly Paint['Retrieving documents', :cyan] do
          api.list
        end
        display_table(documents)
      end

      def show(id, options)
        assert_signed_in
        doc = whirly Paint["Retrieving document #{id}", :cyan] do
          api.get(id)
        end
        display_content(doc, options)
      rescue Errors::MultipleDocsFound => e
        display_table(e.docs)
      end

      def download(args, options)
        assert_signed_in

        id = args.first.strip
        doc = whirly Paint["Downloading document #{id}", :cyan] do
          api.get(id)
        end
        save(doc, output: options[:output])
      end

      private

      def assert_signed_in
        raise Errors::NotSignedIn unless Config::AccountConfig.new.signed_in?
      end

      def save(doc, output:)
        filename =
          if output
            output
          else
            get_unique_filename(with_extension(doc.filename, doc.content_type))
          end
        puts("Saving file to #{filename.inspect}")
        File.write(filename, doc.content)
      end

      def with_extension(filename, content_type)
        if content_type == 'text/markdown' && File.extname(filename).empty?
          "#{filename}.md"
        else
          filename
        end
      end

      def get_unique_filename(filename)
        return filename unless File.exist?(filename)

        candidate = filename
        i = 1
        loop do
          break if i > 99
          candidate = "#{filename}.#{i}"
          if File.exists?(candidate)
            i += 1
          else
            break
          end
        end
        candidate
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

      def pretty_content(doc, pretty:)
        if $stdout.tty? && pretty && doc.content_type == 'text/markdown'
          colors = 256
          begin
            TTY::Markdown.parse(
              doc.content.force_encoding('UTF-8'),
              colors: colors
            )
          rescue
            if colors > 16
              colors = 16
              retry
            end
            doc.content
          end
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
        when 'application/x-shellscript'
          'Shellscript'
        when 'text/plain', /^text\//, 'application/json'
          'Text'
        else
          "Unknown"
        end
      end

      # Return sensible lengths to which locations and filename can be
      # truncated to avoid wrapping.
      #
      # The current algorithm can result in unnecessarily truncated locations.
      def truncate_lengths(documents)
        return [nil, nil] if documents.empty?
        max_location_length = documents.map { |d| d.locations.length }.max
        max_filename_length = documents.map { |d| d.filename.length }.max

        # We make a few assumptions here.
        #  - 11 cols is sufficient to display the content type.  The longest
        #    we currently have is `Spreadsheet`.
        #  - There are 3 columns.
        type_width = 11
        num_cols = 3
        padding = num_cols * 3 + 1

        # The available cols to split between locations and filename
        available_cols = TTY::Screen.width - type_width - padding

        if max_location_length + max_filename_length <= available_cols
          # No truncation necessary.
          [ max_location_length, max_filename_length ]
        else
          # Let's give 30% to locations unless it needs less.
          location_cols = [available_cols * 0.3, max_location_length].min.to_i

          # The filename gets everything else. Even if it doesn't need this
          # much.
          filename_cols = available_cols - location_cols

          [ location_cols, filename_cols ]
        end
      end

      def word_wrap(
        text,
        line_width: 80,
        break_sequence: "\n",
        split_reqexes: ['\s+', '[-_]', '\s+|[-_]' ]
      )
        split_reg = split_reqexes[0] || '\s+|[-_]'
        replacement = split_reg == '\s+' ?
          "\\1#{break_sequence}" :
          "\\1#{break_sequence}\\2"
        text.split("\n").collect! do |line|
          if line.length > line_width
            wrapped_line = line.gsub(
              /(.{1,#{line_width}})(#{split_reg}|$)/,
                replacement
            ).strip
            if wrapped_line.split(break_sequence).any?{|l| l.length > line_width}
              word_wrap(
                text,
                line_width: line_width,
                break_sequence: break_sequence,
                split_reqexes: split_reqexes[1..-1],
              )
            else
              wrapped_line
            end
          else
            line
          end
        end * break_sequence
      end

      def display_table(documents)
        pretty_content_type = self.method(:pretty_content_type)
        word_wrap = method(:word_wrap)
        location_cols, filename_cols = truncate_lengths(documents)

        table = Table.build do |t|
          headers 'Filename', 'Locations', 'Type'
          documents.each do |doc|
            if $stdout.tty?
              # NOTE: If changing this also change `truncate_lengths`.
              row(
                Paint[word_wrap.call(doc.filename, line_width: filename_cols), :cyan],
                Paint[word_wrap.call(doc.locations, line_width: location_cols), :yellow],
                pretty_content_type.(doc.content_type)
              )
            else
              row(
                doc.filename,
                doc.locations,
                pretty_content_type.(doc.content_type),
                doc.id,
              )
            end
          end
        end

        if $stdout.tty?
          if documents.empty?
            puts Paint["No documents found.", :red]
          else
            table.emit
          end
        else
          table.emit(renderer: Docs::TsvRenderer)
        end
      end

      def display_content(doc, options)
        printable =
          case doc.content_type
          when /^text\//
            true
          else
            false
          end

        if printable
          content = pretty_content(doc, pretty: !options[:no_pretty])
          if options[:no_pager]
            puts content
          else
            ENV['LESS'] ||= '-FRX'
            TTY::Pager.new.page(content)
          end
        else
          $stderr.puts("Unable to show binary file. " +
                       "You can #{Paint['download', :white]} it instead.")
        end
      end
    end
  end
end
