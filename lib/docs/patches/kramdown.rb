# =============================================================================
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
# https://github.com/openflighthpc/flight-env
# ==============================================================================

module Kramdown
  module Converter
    class Base
      # Patch to add `**` in call to `new`.
      def self.convert(tree, options = {})
        converter = new(tree, **::Kramdown::Options.merge(options.merge(tree.options[:options] || {})))

        apply_template(converter, '') if !converter.options[:template].empty? && converter.apply_template_before?
        result = converter.convert(tree)
        result.encode!(tree.options[:encoding]) if result.respond_to?(:encode!) && result.encoding != Encoding::BINARY
        result = apply_template(converter, result) if !converter.options[:template].empty? && converter.apply_template_after?

        [result, converter.warnings]
      end
    end
  end
end

module TTY
  module Markdown
    # Patch to add `**` in call to `highlight`.
    class Parser < Kramdown::Converter::Base
      def convert_codespan(el, opts)
        raw_code = Strings.wrap(el.value, @width)
        highlighted = SyntaxHighliter.highlight(raw_code, **@color_opts.merge(opts))
        code = highlighted.split("\n").map.with_index do |line, i|
                if i.zero? # first line
                  line
                else
                  line.insert(0, ' ' * @current_indent)
                end
              end
        opts[:result] << code.join("\n")
      end
    end
  end
end
