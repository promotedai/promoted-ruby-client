# Deploy

1. Update version number.
2. Get credentials for deployment from 1password.
3. Modify `promoted-ruby-client.gemspec`'s push block.
4. Run `gem build promoted-ruby-client.gemspec` to generate `gem`.
5. Run (using new output) `gem push promoted-ruby-client-0.1.20.gem`
6. Update README with new version.
