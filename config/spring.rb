%w(
  .ruby-version
  .rbenv-vars
  tmp/restart.txt
  tmp/caching-dev.txt
  config/credentials.yml
  config/credentials.yml.enc
).each { |path| Spring.watch(path) }
