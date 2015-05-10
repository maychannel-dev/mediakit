require 'active_support/ordered_hash'

module Mediakit
  class FFmpeg
    # presentation of ffmpeg runners option
    #
    # SYNOPSIS
    # ffmpeg [global_options] {[input_file_options] -i input_file} ... {[output_file_options] output_file} ...
    #
    class Options
      attr_reader(:global, :inputs, :output)
      # constructor
      #
      # @option args [Mediakit::FFmpeg::Options::GlobalOption]
      # @option args [Array<Mediakit::FFmpeg::Options::InputFileOption>] array object Mediakit::FFmpeg::Options::InputOption
      # @option args [Mediakit::FFmpeg::Options::OutputFileOption]
      def initialize(*args)
        @global, @inputs, @output = nil, [], nil
        args.each do |option|
          add_option(option)
        end
      end

      def add_option(option)
        return if option.nil?
        case option
        when GlobalOption
          set_global(option)
        when InputFileOption
          add_input(option)
        when OutputFileOption
          set_output(option)
        else
          raise(ArgumentError)
        end
      end

      def compose
        composed_string = ''
        composed_string << "#{global}" if global
        composed_string << " #{inputs.map(&:compose).join(' ')}" if inputs && !inputs.empty?
        composed_string << " #{output}" if output
        composed_string
      end

      alias_method :to_s, :compose

      private

      def set_global(global)
        @global = global
      end

      def add_input(input)
        @inputs.push(input)
      end

      def set_output(output)
        @output = output
      end

      # Base class for Options
      class OrderedHash < ActiveSupport::OrderedHash
        # initializer
        #
        # @param options [Hash] initial option values
        def initialize(options = {})
          options.each { |key, value| raise_if_invalid_arg_error(key, value) } if options
          self.merge!(options) if options && options.kind_of?(Hash)
        end

        def []=(key, value)
          raise_if_invalid_arg_error(key, value)
          super
        end

        def compose
          self.map { |key, value| struct_option(key, value) }.compact.join(' ')
        end

        def to_s
          compose
        end

        protected

        def raise_if_invalid_arg_error(key, value)
          raise(ArgumentError, "#{self.class} can't accept nil value with key(#{key}).") if value.nil?
        end

        def struct_option(key, value)
          case value
          when TrueClass, FalseClass
            value ? "-#{key}" : nil
          else
            "-#{key} #{value}"
          end
        end
      end

      class GlobalOption < OrderedHash
      end

      class OptionPathPair
        attr_reader(:options, :path)

        def initialize(options:, path:)
          @options = options
          @path    = path
        end

        def compose
          raise(NotImplementedError)
        end

        def to_s
          compose
        end
      end

      class InputFileOption < OptionPathPair
        # @param options [Hash] input options
        # @param path [String] input file path
        def initialize(options:, path:)
          ordered_hash = OrderedHash.new(options)
          super(options: ordered_hash, path: path)
        end

        def compose
          "#{options} -i #{path}"
        end
      end

      class OutputFileOption < OptionPathPair
        # @param options [Hash] output options
        # @param path [String] output file path
        def initialize(options:, path:)
          ordered_hash = OrderedHash.new(options)
          super(options: ordered_hash, path: path)
        end

        def compose
          "#{options} #{path}"
        end
      end

      class InputFileOptionCollection
        attr_reader(:input_file_options)

        # @param *input_file_options [Mediakit::FFmpeg::InputFileOptions]
        def initialize(*input_file_options)
          @options = input_file_options
        end

        def empty?
          @options.empty?
        end

        def compose
          @options.map(&:compose).join(' ')
        end

        alias_method :to_s, :compose
      end

      class QuoteString
        def initialize(string)
          @string = string
        end

        def to_s
          "\"#{@string}\""
        end
      end

      # see https://www.ffmpeg.org/ffmpeg.html#Stream-specifiers-1
      class StreamSpecifier
        attr_reader(:stream_index, :stream_type, :program_id, :metadata_tag_key, :metadata_tag_value, :usable)
        STREAM_TYPES = ['v', 'a', 's'].freeze

        def initialize(stream_index: nil, stream_type: nil, program_id: nil, metadata_tag_key: nil, metadata_tag_value: nil, usable: nil)
          raise(ArgumentError, "invalid args stream_type = #{stream_type}") if stream_type && !STREAM_TYPES.include?(stream_type)
          @stream_index       = stream_index
          @stream_type        = stream_type
          @program_id         = program_id
          @metadata_tag_key   = metadata_tag_key
          @metadata_tag_value = metadata_tag_value
          @usable             = usable
        end

        def to_s
          case
          when stream_index?, stream_type?
            stream_specifier
          when program?
            program_specifier
          when meta?
            metadata_specifier
          when usable?
            usable_specifier
          else
            raise(RuntimeError)
          end
        end

        private

        def stream_specifier
          [stream_type, stream_index].compact.join(':')
        end

        def program_specifier
          ["p:#{program_id}", stream_index].compact.join(':')
        end

        def metadata_specifier
          [metadata_tag_key, metadata_tag_value].compact.join(':')
        end

        def usable_specifier
          'u'
        end

        def stream_index?
          !stream_index.nil?
        end

        def stream_type?
          !stream_type.nil?
        end

        def meta?
          !metadata_tag_key.nil?
        end

        def program?
          !program_id.nil?
        end

        def usable?
          !usable.nil?
        end
      end
    end
  end
end
