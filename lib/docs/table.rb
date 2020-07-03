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
# https://github.com/alces-flight/flight-docs
# ==============================================================================
require 'tty-table'

module Docs
  class Table
    DEFAULT_PADDING = [0,1].freeze

    class << self
      def build(&block)
        new.build(&block)
      end

      def emit(renderer: nil, &block)
        build(&block).emit(renderer: renderer)
      end
    end

    def initialize
      @table = TTY::Table.new(header: [''])
      @table.header.fields.clear
      @padding = DEFAULT_PADDING
    end

    attr_reader :table

    def build(&block)
      instance_eval(&block)
      self
    end

    def emit(renderer: nil)
      options = {}.tap do |o|
        o[:padding] = @padding unless @padding.nil?
        o[:multiline] = true
      end
      if renderer.nil?
        puts @table.render(:unicode, options)
      else
        puts renderer.new(@table, options).render
      end
    end

    def headers(*titles)
      titles.each_with_index do |v, i|
        @table.header[i] = v
      end
    end

    def padding(*pads)
      @padding = pads.length == 1 ? pads.first : pads
    end

    def row(*vals)
      @table << vals
    end

    def rows(*vals)
      vals.each do |r|
        @table << r
      end
    end
  end
end
