const http = require('http');
const PORT = 8080;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200);
    res.end('OK');
    return;
  }
  if (req.url === '/ready') {
    res.writeHead(200);
    res.end('READY');
    return;
  }
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello from CI/CD Pipeline! Build working.\n');
});

server.listen(PORT, () => {
  console.log(`App running on port ${PORT}`);
});
// auto-trigger test
// auto-trigger test1
// auto-trigger test
// auto-trigger test
// auto-trigger test
// fix: correct branch
// auto-trigger test
// fix: k8s permissions
