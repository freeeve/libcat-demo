module github.com/freeeve/libcatalog-demo

go 1.25

require github.com/freeeve/libcatalog/hugo v0.0.0

// Local dev resolves the Hugo module from the sibling working tree. CI/deploy pins a
// published module version instead (see tasks/003_s3-cloudfront-deploy.md).
replace github.com/freeeve/libcatalog/hugo => ../libcatalog/hugo
