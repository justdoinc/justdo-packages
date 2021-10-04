_.extend JustdoCertMaintainer.prototype,
  pem_fetch_endpoint: "https://curl.se/ca/cacert.pem"
  path_to_cert_bundle_store: "/plugins/justdo-cert-maintainer/lib/assets/"
  cert_bundle_filename: "cacert.pem"
  last_updated_regex: /[A-Z][a-z]{2}\,.*GMT/ # Not strict, but works
