const http = require('http');

const server = http.createServer((req, res) => {
  // Exercice 13 : Route ajoutée via TDD
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OK');
    return;
  }

  // Route initiale
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello, World!\n');
});

module.exports = server;