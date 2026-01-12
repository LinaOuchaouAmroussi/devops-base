const http = require('http');

// Création du serveur
const server = http.createServer((req, res) => {
  
  // Route pour l'exercice TDD (Health Check)
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OK');
    return;
  }

  // Route par défaut (Hello World)
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello, World!\n');
});

// Exportation du serveur pour les tests (app.test.js)
// Note: Le server.listen se trouve dans server.js
module.exports = server;