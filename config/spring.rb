%w(
  .ruby-version
  .rbenv-vars
  tmp/restart.txt
  tmp/caching-dev.txt
  config/secrets.yml
  config/secrets.yml.enc
).each { |path| Spring.watch(path) }
