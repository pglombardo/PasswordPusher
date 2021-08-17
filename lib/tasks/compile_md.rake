SOURCE_FILES = %w[faq tools about promise help].freeze

desc 'Compile markdown files into ERB HighVoltage pages'
task :compile_markdown do
  SOURCE_FILES.each do |f|
    require 'kramdown'
    content = Kramdown::Document.new(File.read("./docs/#{f}.md")).to_html
    File.write("app/views/pages/#{f}.html.erb", content)
  end
end
