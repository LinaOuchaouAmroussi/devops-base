const request = require('supertest');
const server = require('./app');

describe('Tests de l\'application Node.js', () => {

  // Test 1
  it('GET / doit retourner Hello, World!', async () => {
    const res = await request(server).get('/');
    expect(res.statusCode).toEqual(200);
    expect(res.text).toBe('Hello, World!\n');
  });

  // Test 2 (Requis pour l'exercice 13 TDD)
  it('GET /health doit retourner OK', async () => {
    const res = await request(server).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.text).toBe('OK');
  });

});