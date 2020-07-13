#==============================================================================
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
#==============================================================================
module Docs
  module Errors
    DocsError = Class.new(RuntimeError)
    DocNotFound = Class.new(DocsError) do
      def initialize(id)
        super("Unable to find document.")
      end
    end
    DocContentNotFound = Class.new(DocsError) do
      def initialize(id)
        super("Unable to download document.")
      end
    end
    MultipleDocsFound = Class.new(DocsError) do
      def initialize(id, docs)
        super("Multiple documents match the given name")
      end
    end
    ApiUnavailable = Class.new(DocsError) do
      def initialize
        super("Unable to connect to API server.")
      end
    end
  end
end
