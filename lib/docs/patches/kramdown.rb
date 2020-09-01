# ==============================================================================
# The following license applies solely to KramdownConvertPatch
# Modified from:
# https://github.com/gettalong/kramdown/blob/REL_1_16_2/lib/kramdown/converter/base.rb
#
# kramdown - fast, pure-Ruby Markdown-superset converter
# Copyright (C) 2009-2013 Thomas Leitner <t_leitner@gmx.at>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ==============================================================================

require 'kramdown'

module KramdownConverterPatch
  def convert(tree, options = {})
    converter = new(tree, **::Kramdown::Options.merge(options.merge(tree.options[:options] || {})))

    apply_template(converter, '') if !converter.options[:template].empty? && converter.apply_template_before?
    result = converter.convert(tree)
    result.encode!(tree.options[:encoding]) if result.respond_to?(:encode!) && result.encoding != Encoding::BINARY
    result = apply_template(converter, result) if !converter.options[:template].empty? && converter.apply_template_after?

    [result, converter.warnings]
  end
end

class << Kramdown::Converter::Base
  self.prepend KramdownConverterPatch
end

# ==============================================================================
# The following license applies solely to TTYMarkdownParserPatch
# Modified from:
# https://github.com/piotrmurach/tty-markdown/blob/v0.6.0/lib/tty/markdown/parser.rb
# https://github.com/piotrmurach/tty-markdown/blob/93f6fe9096f3096d65dd3e752d9d873fd0f7acd6/lib/tty/markdown/converter.rb
#
# The MIT License (MIT)
#
# Copyright (c) 2018 Piotr Murach
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# ==============================================================================

require 'tty-markdown'
require 'uri'

module TTYMarkdownParserPatch
  def convert_codespan(el, opts)
    raw_code = Strings.wrap(el.value, @width)
    highlighted = TTY::Markdown::SyntaxHighliter.highlight(raw_code, **@color_opts.merge(opts))
    code = highlighted.split("\n").map.with_index do |line, i|
            if i.zero? # first line
              line
            else
              line.insert(0, ' ' * @current_indent)
            end
          end
    opts[:result] << code.join("\n")
  end

  def convert_td(el, opts)
    indent = ' ' * @current_indent
    pipe       = TTY::Markdown.symbols[:pipe]
    styles     = Array(@theme[:table])
    table_data = opts[:table_data]
    result     = opts[:cells]
    suffix     = " #{@pastel.decorate(pipe, *styles)} "
    opts[:result] = []

    inner(el, opts)

    row, column = *find_row_column(table_data, opts[:result])
    cell_widths = distribute_widths(max_widths(table_data))
    cell_width = cell_widths[column]
    cell_height = max_height(table_data, row, cell_widths)
    alignment  = opts[:alignment][column]
    align_opts = alignment == :default ? {} : { direction: alignment }

    wrapped = Strings.wrap(opts[:result].join, cell_width)
    aligned = Strings.align(wrapped, cell_width, **align_opts)
    padded = if aligned.lines.size < cell_height
               Strings.pad(aligned, [0, 0, cell_height - aligned.lines.size, 0])
             else
               aligned.dup
             end

    result << padded.lines.map do |line|
      # add pipe to first column
      (column.zero? ? indent + @pastel.decorate("#{pipe} ", *styles) : '') +
        (line.end_with?("\n") ? line.insert(-2, suffix) : line << suffix)
    end
  end

  def max_width(table_data, col)
    table_data.map do |row|
      Strings.sanitize(row[col].join).lines.map(&:length).max
    end
      .compact
      .max || 0
  end

  def convert_html_element(el, opts)
    if el.value == 'br'
      opts[:result] << "\n"
    else
      raise "HTML elements are not supported"
    end
  end
end

TTY::Markdown::Parser.prepend TTYMarkdownParserPatch
