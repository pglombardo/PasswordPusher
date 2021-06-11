SOURCE_FILES = ['FAQ'].freeze

desc 'Compile markdown files into ERB HighVoltage pages'
task :compile_markdown do
  SOURCE_FILES.each do |f|
    require 'kramdown'
    content = Kramdown::Document.new(File.read('./docs/FAQ.md')).to_html
    File.write('app/views/pages/faq.html.erb', content)
  end

end
