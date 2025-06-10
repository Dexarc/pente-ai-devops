// app/server.js - REVIEWED VERSION with improvements

// 1. Load environment variables from .env file (for local development)
require('dotenv').config();

const express = require('express');
const AWS = require('aws-sdk'); // AWS SDK v2 (consider migrating to v3 for better performance)
const { Client } = require('pg'); // PostgreSQL client

const app = express();
const port = process.env.CONTAINER_PORT || 3000;

// 2. Configure AWS SDK region with better error handling
const awsRegion = process.env.AWS_REGION || 'us-east-1';
AWS.config.update({ region: awsRegion });

// Add timeout configuration for better reliability
const ssm = new AWS.SSM({
    maxRetries: 3,
    timeout: 30000 // 30 seconds timeout
});

// 3. Database connection configuration from environment variables
const dbHost = process.env.DB_HOST;
const dbPort = parseInt(process.env.DB_PORT || '5432');
const dbName = process.env.DB_NAME;
const dbUsernameSsmParam = process.env.DB_USERNAME_SSM_PARAM;
const dbPasswordSsmParam = process.env.DB_PASSWORD_SSM_PARAM;

// IMPROVEMENT: Add validation for required environment variables
function validateEnvironmentVariables() {
    const required = ['DB_HOST', 'DB_NAME', 'DB_USERNAME_SSM_PARAM', 'DB_PASSWORD_SSM_PARAM'];
    const missing = required.filter(env => !process.env[env]);
    
    if (missing.length > 0) {
        console.error('ERROR: Missing required environment variables:', missing.join(', '));
        process.exit(1);
    }
    
    console.log('✅ All required environment variables are present');
}

// IMPROVEMENT: Enhanced SSM parameter fetching with retry logic
async function getSsmParameter(paramName, withDecryption = false) {
    console.log(`Attempting to fetch SSM parameter: ${paramName}`);
    
    try {
        const params = {
            Name: paramName,
            WithDecryption: withDecryption
        };
        
        const data = await ssm.getParameter(params).promise();
        console.log(`✅ Successfully fetched parameter: ${paramName}`);
        return data.Parameter.Value;
        
    } catch (error) {
        console.error(`❌ Failed to fetch SSM parameter ${paramName}:`, {
            code: error.code,
            message: error.message,
            statusCode: error.statusCode
        });
        
        // IMPROVEMENT: More specific error messages based on error type
        if (error.code === 'ParameterNotFound') {
            throw new Error(`SSM Parameter '${paramName}' does not exist. Please create it first.`);
        } else if (error.code === 'AccessDenied') {
            throw new Error(`Access denied to SSM parameter '${paramName}'. Check IAM permissions.`);
        } else if (error.code === 'InvalidKeyId') {
            throw new Error(`Invalid KMS key for parameter '${paramName}'. Check KMS permissions.`);
        } else {
            throw new Error(`Failed to retrieve parameter '${paramName}': ${error.message}`);
        }
    }
}

// IMPROVEMENT: Enhanced database connection with connection pooling options
async function getGreetingFromDb() {
    let client;

    try {
        // Fetch DB credentials from SSM Parameter Store
        console.log('🔐 Fetching database credentials from SSM...');
        const dbUsername = await getSsmParameter(dbUsernameSsmParam);
        const dbPassword = await getSsmParameter(dbPasswordSsmParam, true);

        // IMPROVEMENT: Enhanced connection configuration
        const dbConfig = {
            host: dbHost,
            port: dbPort,
            database: dbName,
            user: dbUsername,
            password: dbPassword,
            // IMPROVEMENT: Better SSL configuration
            ssl: process.env.NODE_ENV === 'production' ? {
                rejectUnauthorized: true,
                // Add CA certificate for production if needed
                // ca: fs.readFileSync('/path/to/ca-certificate.crt').toString()
            } : {
                rejectUnauthorized: false // Only for development
            },
            // IMPROVEMENT: Connection timeout settings
            connectionTimeoutMillis: 30000, // 30 seconds
            idleTimeoutMillis: 30000,
            query_timeout: 60000, // 60 seconds for queries
        };

        console.log(`🔄 Connecting to PostgreSQL: ${dbHost}:${dbPort}/${dbName} as user ${dbUsername}`);
        client = new Client(dbConfig);
        
        await client.connect();
        console.log('✅ Successfully connected to PostgreSQL');

        // IMPROVEMENT: More robust query with error handling
        const query = 'SELECT message FROM greetings ORDER BY created_at DESC LIMIT 1';
        console.log(`🔍 Executing query: ${query}`);
        
        const result = await client.query(query);

        if (result.rows.length > 0) {
            console.log('✅ Successfully retrieved greeting from database');
            return result.rows[0].message;
        } else {
            console.log('⚠️  No greetings found in database');
            return 'No greeting found in the database. Please insert one using: INSERT INTO greetings (message, created_at) VALUES (\'Hello from DB!\', NOW());';
        }

    } catch (error) {
        console.error('❌ Database operation failed:', {
            name: error.name,
            message: error.message,
            code: error.code
        });
        
        // IMPROVEMENT: More user-friendly error messages
        if (error.message.includes('ENOTFOUND') || error.message.includes('ECONNREFUSED')) {
            return 'Database connection failed: Cannot reach the database server. Please check network connectivity.';
        } else if (error.message.includes('authentication failed')) {
            return 'Database authentication failed: Invalid username or password.';
        } else if (error.message.includes('does not exist')) {
            return 'Database error: The specified database or table does not exist.';
        } else {
            return `Database error: ${error.message}`;
        }
        
    } finally {
        if (client) {
            try {
                await client.end();
                console.log('✅ Disconnected from PostgreSQL');
            } catch (endError) {
                console.error('❌ Error closing database connection:', endError.message);
            }
        }
    }
}

// IMPROVEMENT: Add middleware for basic logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - ${req.ip}`);
    next();
});

// --- Express.js Routes ---

// IMPROVEMENT: Enhanced main route with better error handling
app.get('/', async (req, res) => {
    try {
        console.log('🌐 Processing request to /');
        const dbMessage = await getGreetingFromDb();
        
        // IMPROVEMENT: Better HTML structure and styling
        res.send(`
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Node.js Hello-DB App</title>
                <style>
                    body { 
                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                        display: flex; 
                        flex-direction: column; 
                        align-items: center; 
                        justify-content: center; 
                        min-height: 100vh; 
                        margin: 0; 
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: #333; 
                        padding: 20px;
                        box-sizing: border-box;
                    }
                    .container {
                        background: rgba(255, 255, 255, 0.95);
                        border-radius: 15px;
                        padding: 30px;
                        box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                        text-align: center;
                        max-width: 600px;
                    }
                    h1 { 
                        color: #4a5568; 
                        margin-bottom: 20px;
                        font-size: 2.5em;
                    }
                    .db-message { 
                        color: #2d3748; 
                        font-size: 1.2em; 
                        margin: 20px 0;
                        padding: 15px;
                        background-color: #e2e8f0;
                        border-radius: 8px;
                        border-left: 4px solid #4299e1;
                    }
                    .info { 
                        color: #718096; 
                        font-size: 0.9em; 
                        line-height: 1.6;
                        margin: 10px 0;
                    }
                    .status {
                        position: absolute;
                        top: 20px;
                        right: 20px;
                        background: #48bb78;
                        color: white;
                        padding: 5px 15px;
                        border-radius: 20px;
                        font-size: 0.8em;
                    }
                </style>
            </head>
            <body>
                <div class="status">🟢 Online</div>
                <div class="container">
                    <h1>🌍 Hello World!</h1>
                    <p class="info">A message from your database:</p>
                    <div class="db-message"><strong>${dbMessage}</strong></div>
                    <p class="info">This application connects to PostgreSQL via credentials fetched securely from AWS SSM Parameter Store.</p>
                    <p class="info">Running on AWS Fargate via an Application Load Balancer.</p>
                    <p class="info"><small>Timestamp: ${new Date().toISOString()}</small></p>
                </div>
            </body>
            </html>
        `);
        
    } catch (error) {
        console.error('❌ Error processing request:', error);
        res.status(500).send(`
            <h1>Internal Server Error</h1>
            <p>Sorry, something went wrong: ${error.message}</p>
        `);
    }
});

// IMPROVEMENT: Enhanced health check endpoint
app.get('/health', async (req, res) => {
    const healthCheck = {
        status: 'OK',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: {
            nodeVersion: process.version,
            platform: process.platform,
            memory: process.memoryUsage()
        }
    };
    
    try {
        // Optional: Test database connectivity for health check
        // await getGreetingFromDb(); // Uncomment if you want to test DB in health check
        res.status(200).json(healthCheck);
    } catch (error) {
        healthCheck.status = 'ERROR';
        healthCheck.error = error.message;
        res.status(503).json(healthCheck);
    }
});

// IMPROVEMENT: Add a debug endpoint for troubleshooting
app.get('/debug', (req, res) => {
    res.json({
        environment: {
            NODE_ENV: process.env.NODE_ENV,
            AWS_REGION: process.env.AWS_REGION,
            DB_HOST: process.env.DB_HOST,
            DB_PORT: process.env.DB_PORT,
            DB_NAME: process.env.DB_NAME,
            DB_USERNAME_SSM_PARAM: process.env.DB_USERNAME_SSM_PARAM,
            DB_PASSWORD_SSM_PARAM: process.env.DB_PASSWORD_SSM_PARAM,
            // Don't expose sensitive values
            AWS_ACCESS_KEY_ID: process.env.AWS_ACCESS_KEY_ID ? 'SET' : 'NOT SET',
            AWS_SECRET_ACCESS_KEY: process.env.AWS_SECRET_ACCESS_KEY ? 'SET' : 'NOT SET'
        },
        server: {
            port: port,
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            version: process.version
        }
    });
});

// IMPROVEMENT: Add graceful shutdown handling
process.on('SIGTERM', () => {
    console.log('🔄 SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('🔄 SIGINT received, shutting down gracefully');
    process.exit(0);
});

// Start the server with validation
validateEnvironmentVariables();

app.listen(port, () => {
    console.log('🚀 ===== Hello-DB-App Started =====');
    console.log(`📡 Server listening on port ${port}`);
    console.log(`🗄️  Database: ${dbHost}:${dbPort}/${dbName}`);
    console.log(`🔐 SSM Parameters: ${dbUsernameSsmParam}, ${dbPasswordSsmParam}`);
    console.log(`🌍 AWS Region: ${awsRegion}`);
    console.log(`📝 Endpoints:`);
    console.log(`   - http://localhost:${port}/       (Main app)`);
    console.log(`   - http://localhost:${port}/health (Health check)`);
    console.log(`   - http://localhost:${port}/debug  (Debug info)`);
    console.log('💡 Ensure the "greetings" table exists with columns: message, created_at');
    console.log('=====================================');
});