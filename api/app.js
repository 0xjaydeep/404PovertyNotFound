const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

// Import middleware and routes
const {
  logRequest,
  errorHandler,
  corsOptions,
  securityHeaders,
  rateLimits
} = require('./middleware/validation');

const investmentV3Routes = require('./routes/investmentV3');
const { validateContractAddresses } = require('./config/contracts');

const app = express();

// Security middleware
app.use(helmet());
app.use(securityHeaders);

// CORS
app.use(cors(corsOptions));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use(logRequest);

// Rate limiting
app.use('/api/', rateLimits.general);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

// API routes
app.use('/api/v3', investmentV3Routes);

// API documentation endpoint
app.get('/api/docs', (req, res) => {
  res.json({
    success: true,
    documentation: {
      title: 'InvestmentEngineV3 API',
      version: '1.0.0',
      description: 'REST API for 404 Poverty Not Found - InvestmentEngineV3 with Uniswap V4 integration',
      baseUrl: `${req.protocol}://${req.get('host')}/api/v3`,
      endpoints: {
        'GET /status': 'Get contract status and configuration',
        'GET /plans': 'Get all available investment plans',
        'GET /plans/:planId': 'Get specific investment plan',
        'POST /quote': 'Get investment quote',
        'POST /prepare-investment': 'Prepare investment transaction data',
        'GET /investments/:investmentId': 'Get investment details',
        'GET /users/:userAddress/investments': 'Get user investments',
        'GET /users/:userAddress/portfolio': 'Get user portfolio',
        'GET /events': 'Get recent investment events',
        'GET /stats': 'Get platform statistics'
      },
      authentication: 'None required for read operations',
      rateLimit: '100 requests per 15 minutes per IP',
      errors: {
        400: 'Bad Request - Invalid parameters',
        404: 'Not Found - Resource not found',
        429: 'Too Many Requests - Rate limit exceeded',
        500: 'Internal Server Error - Server error'
      }
    }
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    availableEndpoints: [
      'GET /health',
      'GET /api/docs',
      'GET /api/v3/status',
      'GET /api/v3/plans',
      'POST /api/v3/quote',
      'POST /api/v3/prepare-investment'
    ]
  });
});

// Error handling
app.use(errorHandler);

// Validate configuration on startup
const validateConfig = () => {
  try {
    validateContractAddresses();
    console.log('✅ Contract configuration validated');
  } catch (error) {
    console.error('❌ Configuration validation failed:', error.message);
    process.exit(1);
  }
};

// Start server
const PORT = process.env.PORT || 3000;

const startServer = () => {
  try {
    validateConfig();

    app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   🚀 InvestmentEngineV3 API Server Started                ║
║                                                            ║
║   Port: ${PORT}                                               ║
║   Environment: ${process.env.NODE_ENV || 'development'}                                     ║
║   Network: ${process.env.NETWORK || 'localhost'}                                        ║
║                                                            ║
║   📚 API Documentation: http://localhost:${PORT}/api/docs     ║
║   🔍 Health Check: http://localhost:${PORT}/health           ║
║   🎯 Base URL: http://localhost:${PORT}/api/v3               ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
const gracefulShutdown = (signal) => {
  console.log(`\n🛑 Received ${signal}. Shutting down gracefully...`);

  setTimeout(() => {
    console.log('🔴 Force shutting down...');
    process.exit(1);
  }, 10000);

  process.exit(0);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Only start server if this file is run directly
if (require.main === module) {
  startServer();
}

module.exports = app;