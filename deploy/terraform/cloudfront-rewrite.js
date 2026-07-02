// CloudFront Function (viewer-request) for Hugo "pretty" URLs on an S3/OAC origin
// (tasks/003). S3 behind OAC does no directory-index resolution, so a request for
// "/works/wid/" or "/about/" must be rewritten to the object Hugo actually wrote,
// "/works/wid/index.html". Requests that already name a file (contain a dot in the
// last path segment) pass through unchanged.
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith("/")) {
    request.uri = uri + "index.html";
  } else if (!uri.split("/").pop().includes(".")) {
    request.uri = uri + "/index.html";
  }
  return request;
}
