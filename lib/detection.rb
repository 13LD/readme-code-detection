
class Detection

  def initialize(url)
    read_markdown(url)
  end

  def run
    markdown_update if system('pip3 install guesslang')
  end

  def markdown_update
    blocks_count = 0
    data = ""
    File.open(PATH, 'r+').each do |line|
      data << line
    end

    parsed = parsed_data(data, blocks_count)

    lang = language_prediction(parsed)
    update_input_readme(blocks_count, lang)
  end

  def parsed_data(data, blocks_count)
    parsed = []

    test = data.split(/```/)[1..-1].each_slice(1).to_a
    test.each do |t|
      blocks_count += 1
      if blocks_count % 2 == 1
        parsed << t.join(" ")
      end
    end

    parsed
  end

  def language_prediction(parsed)
    predict_response = predict_response(parsed)
    parsed_prediction = parse_prediction(predict_response)

    parsed_prediction.map do |t|
      lang << t.join(' ').split(/\n/).first.downcase!
    end
  end

  def predict_response(data)
    predict_response = ''

    data.each_with_index do |block, index|
      file_name = "sample_data/block#{index}"
      open(file_name, 'w') { |f| f.puts block }
      line_count = `wc -l "#{file_name}"`.strip.split(' ')[0].to_i
      predict_response << line_count > 2 ? `guesslang -i sample_datablock#{index}` : 'guesslang.__main__ INFO The source code is written in 1 line'
    end

    predict_response
  end

  def parse_prediction(predict_response)
    predict_response.split(
        /guesslang.__main__ INFO The source code is written in /
    )[1..-1].each_slice(1).to_a
  end

  def read_markdown(url)
    user_repo = url.slice(url.index('.com')..-1)
    system("curl https://raw.githubusercontent#{user_repo}/master/README.md > sample_data/README.md")
  end

  def update_input_readme(blocks_count, lang)
    lang.map!{ |x| x.nil? ? '' : x }

    new_data = get_blocks_data(blocks_count, lang)

    File.open(PATH, "w") {|file| file.puts new_data }
  end

  def get_blocks_data(blocks_count, lang)
    i = 0
    new_data = ''

    File.open(PATH, 'r+').each do |line|
      if line.include? "```" and blocks_count % 2 == 0
        new_data << "```" + lang[i] + "\n"
        i += 1
        blocks_count -= 1
      elsif line.include? "```" and blocks_count % 2 == 1
        new_data << line
        blocks_count -= 1
      else
        new_data << line
      end
    end

    new_data
  end
end

