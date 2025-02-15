final List<String> predefinedHeaderKeys = [
  'Content-Type',
  'Accept',
  'Authorization',
  'User-Agent',
  'Host',
  'Connection',
  'Cache-Control',
  'Accept-Encoding',
  'Accept-Language',
  'Content-Length',
  'Cookie',
  'Referer',

  // Useful conditionals & metadata
  'If-Modified-Since',
  'If-None-Match',
  'Range',
  'Accept-Charset',
  'ETag',
  'Expires',
  'Last-Modified',
  'Pragma',
  'Date',
  'Location',

  // Common for custom/advanced usage
  'DNT', // Do Not Track
  'X-Requested-With',
  'X-HTTP-Method-Override',
  'Origin',
];

final List<String> predefinedHeaderValues = [
  'application/json',
  'application/x-www-form-urlencoded',
  'multipart/form-data',
  'text/plain',
  'text/html',
  'application/xml',
  'application/octet-stream',
  'application/pdf',
  'image/png',
  'image/jpeg',

  // Common Accept values (often combined, e.g. "text/html,application/json")
  '*/*', // fallback

  // Authorization placeholders
  'Bearer <token>',
  'Basic <base64encoded>',
  'Digest <digest>',

  // Common Cache-Control values
  'no-cache',
  'no-store',
  'max-age=0',
  'must-revalidate',
  'public',
  'private',

  // Accept-Encoding
  'gzip',
  'deflate',
  'br',

  // Accept-Language
  'en-US',
  'en',

  // Connection
  'keep-alive',
  'close',

  // Example dates / tokens for manual testing
  'Thu, 01 Dec 1994 16:00:00 GMT', // For Expires or Last-Modified
  '0', // e.g., "Expires: 0" or "Content-Length: 0"

  // Transfer-Encoding / multipart usage
  'chunked',
  'boundary=----WebKitFormBoundary'
];