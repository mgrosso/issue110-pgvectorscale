module GenerateIssue110TestData

  METADATA = [
    '{"name": "test1"}',
    '{"name": "test2"}',
    '{"name": "test3"}',
    '{"name": "test4"}',
    '{"name": "test5"}',
    '{"name": "test6"}',
    '{"name": "test7"}',
    '\N',
  ]

  CONTENTS = [
    'hello world1',
    'hello world2',
    'hello world3',
    'hello world4',
    'hello world5',
    'hello pipey \|world6',
    'hello world7',
    'hello world8',
  ]

  BASE_VECTORS = [
    [0.1, 0.3, 0.6],
    [0.2, 0.4, 0.4],
    [0.01, 0.2, 0.79],
    [0.98, 0.01, 0.01],
    [0.15, 0.35, 0.5],
    [0.25, 0.45, 0.3],
    [0.01, 0.25, 0.74],
    [0.88, 0.05, 0.05],
  ]

  # takes vector of length 3 and expands it to 128
  def expand_vector(v)
    a = v.dup
    a << 1.0
    a * 32
  end

  # add jitter to a vector so we don't have exact matches
  def jitter_vector(v)
    v.map { |x| x + (rand - 0.5) * 0.01 }
  end

  # generate a row of data for the COPY file.
  def generate_row(cluster_index)
    metadata_row = METADATA[cluster_index]
    contents_row = CONTENTS[cluster_index]
    base_vector = BASE_VECTORS[cluster_index]
    expanded_vector = jitter_vector(expand_vector(base_vector)).to_s
    [metadata_row, contents_row, expanded_vector].join("|")
  end

  def yield_n_rows(n)
    n.times.each do |i|
      yield generate_row(i % METADATA.size)
    end
  end

  def generate_copy_file(filename, n)
    File.open(filename, 'w') do |f|
      yield_n_rows(n) do |row|
        f.puts(row)
      end
    end
  end

  def gen32k
    generate_copy_file('test32k.txt', 32 * 1024)
  end
end


if __FILE__ == $0
  include GenerateIssue110TestData
  if ARGV.empty?
    gen32k
  elsif ARGV[0] == 'query_vector'
    puts expand_vector [0.11, 0.29, 0.61]
  elsif ARGV.size == 2
    filename = ARGV[0]
    row_count = ARGV[1].to_i
    generate_copy_file(filename, row_count)
  else
    puts "Usage: #{$0} <filename> <row_count>"
  end
end
