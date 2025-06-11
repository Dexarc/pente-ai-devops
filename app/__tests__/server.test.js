// app/__tests__/server.test.js
const supertest = require('supertest');

// Mock pg module
const mockClient = {
  connect: jest.fn(),
  query: jest.fn(),
  end: jest.fn(),
};

jest.mock('pg', () => ({
  Client: jest.fn(() => mockClient)
}));

// Mock AWS SDK
const mockGetParameter = jest.fn();
jest.mock('aws-sdk', () => ({
  config: { update: jest.fn() },
  SSM: jest.fn(() => ({
    getParameter: mockGetParameter
  }))
}));

const { Client } = require('pg');
const AWS = require('aws-sdk');

// Mock console methods to avoid noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  error: jest.fn(),
};

// Set up environment variables
process.env = {
  NODE_ENV: 'test',
  DB_HOST: 'test-host',
  DB_NAME: 'test-db',
  DB_USERNAME_SSM_PARAM: '/test/username',
  DB_PASSWORD_SSM_PARAM: '/test/password',
  CONTAINER_PORT: '80'
};

// Import app after mocks are set up
const { app, getSsmParameter, getGreetingFromDb, validateEnvironmentVariables } = require('../server');

describe('Environment Validation', () => {
  const originalExit = process.exit;
  
  beforeAll(() => {
    process.exit = jest.fn();
  });
  
  afterAll(() => {
    process.exit = originalExit;
  });

  test('passes with all required env vars', () => {
    validateEnvironmentVariables();
    expect(process.exit).not.toHaveBeenCalled();
  });

  test('fails when env vars missing', () => {
    const originalHost = process.env.DB_HOST;
    delete process.env.DB_HOST;
    
    validateEnvironmentVariables();
    expect(process.exit).toHaveBeenCalledWith(1);
    
    process.env.DB_HOST = originalHost;
  });
});

describe('SSM Parameter', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('fetches parameter successfully', async () => {
    mockGetParameter.mockReturnValue({
      promise: () => Promise.resolve({
        Parameter: { Value: 'test-value' }
      })
    });

    const result = await getSsmParameter('/test/param');
    expect(result).toBe('test-value');
  });

  test('handles parameter not found', async () => {
    const error = new Error('Not found');
    error.code = 'ParameterNotFound';
    
    mockGetParameter.mockReturnValue({
      promise: () => Promise.reject(error)
    });

    await expect(getSsmParameter('/missing/param'))
      .rejects.toThrow("SSM Parameter '/missing/param' does not exist");
  });
});

describe('Database Connection', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    
    // Mock successful SSM responses for username and password
    mockGetParameter
      .mockReturnValueOnce({
        promise: () => Promise.resolve({ Parameter: { Value: 'testuser' } })
      })
      .mockReturnValueOnce({
        promise: () => Promise.resolve({ Parameter: { Value: 'testpass' } })
      });
  });

  test('fetches greeting successfully', async () => {
    mockClient.connect.mockResolvedValue();
    mockClient.query.mockResolvedValue({
      rows: [{ message: 'Hello from DB!' }]
    });
    mockClient.end.mockResolvedValue();

    const result = await getGreetingFromDb();
    expect(result).toBe('Hello from DB!');
    expect(mockClient.connect).toHaveBeenCalled();
    expect(mockClient.end).toHaveBeenCalled();
  });

  test('handles connection failure', async () => {
    mockClient.connect.mockRejectedValue(new Error('ECONNREFUSED'));
    mockClient.end.mockResolvedValue();

    const result = await getGreetingFromDb();
    expect(result).toContain('Database connection failed');
    expect(mockClient.end).toHaveBeenCalled();
  });

  test('handles empty results', async () => {
    mockClient.connect.mockResolvedValue();
    mockClient.query.mockResolvedValue({ rows: [] });
    mockClient.end.mockResolvedValue();

    const result = await getGreetingFromDb();
    expect(result).toContain('No greeting found');
  });
});

describe('API Routes', () => {
  const request = supertest(app);

  // Mock the database function to avoid actual DB calls
  jest.mock('../server', () => ({
    ...jest.requireActual('../server'),
    getGreetingFromDb: jest.fn(() => Promise.resolve('Mocked greeting'))
  }));

  test('GET / returns HTML page', async () => {
    const response = await request.get('/');
    
    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toContain('text/html');
    expect(response.text).toContain('Hello World!');
  });

  test('GET /health returns status', async () => {
    const response = await request.get('/health');
    
    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toContain('application/json');
    expect(response.body.status).toBe('OK');
    expect(response.body.uptime).toBeGreaterThan(0);
  });

  test('GET /debug returns environment info', async () => {
    const response = await request.get('/debug');
    
    expect(response.status).toBe(200);
    expect(response.body.environment.DB_HOST).toBe('test-host');
    expect(response.body.server.port).toBe('80'); // Changed back to string
  });
});