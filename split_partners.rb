#!/usr/bin/env ruby

require 'optparse'
require 'csv'

# For each line in the original csv, we'll make two lines in our
# output file. The first line will be data using the column headers from
# left column below. The second line will be data using the column
# headers from the right column below.
COLUMNS = [
            %w( google_doc_id  google_doc_id ),
            %w( id             p_id ),
            %w( gender         p_gender ),
            %w( ethnic         p_ethnic ),
            %w( relate         p_relate ),
            %w( marital        p_marital ),
            %w( sexorien       p_sexorien ),
            %w( rel_length     p_rel_length ),
            %w( total_DAS      total_p_DAS ),
            %w( total_fis      total_p_fis ),
            %w( total_ISS      total_p_ISS ),
            %w( total_SCS      total_p_SCS ),
            %w( total_SCS_IP   total_SCS_IP_P ),
          ]

class SplitPartners
  def self.parse(args)
    options = {}
    options[:remove_blank_lines] = true
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #$0 [options]"
      opts.separator ""
      opts.separator "Specific options:"
      opts.on("-i", "--input=INPUT_FILE", "REQUIRED: Input file") do |input|
        options[:input] = input
      end

      opts.on("-o", "--output=OUTPUT_FILE", "REQUIRED: Output file") do |output|
        options[:output] = output
      end

      opts.on("-b", "--[no-]blanks", "Include blank lines") do |show_blank_lines|
        options[:remove_blank_lines] = !show_blank_lines
      end

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opts.parse!(args)

    unless options[:input] && options[:output]
      puts opts
      exit
    end

    options
  end

  def initialize(options)
    @input  = options[:input]
    @output = options[:output]
    @remove_blank_lines = options[:remove_blank_lines]
  end

  def header
    COLUMNS.map(&:first).join(',')
  end

  def puts(*args)
    @out.puts *args
    $stdout.puts *args
  end

  def write(*args)
    @out.write *args
    $stdout.write *args
  end

  def open_output_file
    @out = File.open(@output, 'w')
  end

  def close_output_file
    @out.close
  end

  def run
    open_output_file
    puts header
    CSV.foreach(@input, :headers => :first_row) do |line|
      split = SplitLine.split(line, @remove_blank_lines)
      write split
    end
  ensure
    close_output_file
  end
end

class SplitLine
  def self.split(*args)
    new(*args).run
  end

  def initialize(line, remove_blanks=false)
    @line = line
    @remove_blanks = remove_blanks
  end

  def line_to_string(line)
    line.join(',') << "\n"
  end

  def line1
    COLUMNS.map { |c| @line[c.first] }
  end

  def line2
    COLUMNS.map { |c| @line[c.last] }
  end

  def missing_values?
    (line1 + line2).any? { |v| v.strip == "" }
  end

  def run
    return '' if @remove_blanks && missing_values?
    line_to_string(line1) + line_to_string(line2)
  end
end

if __FILE__ == $0
  options = SplitPartners.parse(ARGV)
  SplitPartners.new(options).run
end
