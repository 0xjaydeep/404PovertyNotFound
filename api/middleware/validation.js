const { ethers } = require('ethers');
const { body, param, query, validationResult } = require('express-validator');

// Custom validation functions
const isEthereumAddress = (value) => {
  return ethers.isAddress(value);
};

const isBigIntString = (value) => {
  try {
    BigInt(value);
    return true;
  } catch {
    return false;
  }
};

const isPositiveInteger = (value) => {
  const num = parseInt(value);
  return !isNaN(num) && num > 0;
};

// Validation middleware
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

// Validation rules
const validateUserAddress = [
  param('userAddress')
    .custom(isEthereumAddress)
    .withMessage('Invalid Ethereum address'),
  handleValidationErrors
];

const validateInvestmentId = [
  param('investmentId')
    .isInt({ min: 1 })
    .withMessage('Investment ID must be a positive integer'),
  handleValidationErrors
];

const validatePlanId = [
  param('planId')
    .isInt({ min: 1 })
    .withMessage('Plan ID must be a positive integer'),
  handleValidationErrors
];

const validateQuoteRequest = [
  body('amount')
    .custom(isBigIntString)
    .withMessage('Amount must be a valid number string')
    .custom((value) => BigInt(value) > 0)
    .withMessage('Amount must be greater than 0'),
  body('planId')
    .isInt({ min: 1 })
    .withMessage('Plan ID must be a positive integer'),
  handleValidationErrors
];

const validateInvestmentPreparation = [
  body('userAddress')
    .custom(isEthereumAddress)
    .withMessage('Invalid Ethereum address'),
  body('amount')
    .custom(isBigIntString)
    .withMessage('Amount must be a valid number string')
    .custom((value) => BigInt(value) > 0)
    .withMessage('Amount must be greater than 0'),
  body('planId')
    .isInt({ min: 1 })
    .withMessage('Plan ID must be a positive integer'),
  handleValidationErrors
];

const validatePagination = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  handleValidationErrors
];

const validateEventQuery = [
  query('fromBlock')
    .optional()
    .custom((value) => {
      return value === 'latest' || isPositiveInteger(value);
    })
    .withMessage('fromBlock must be "latest" or a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 1000 })
    .withMessage('Limit must be between 1 and 1000'),
  handleValidationErrors
];

// Rate limiting for expensive operations
const rateLimit = require('express-rate-limit');

const createRateLimit = (windowMs, max, message) => {
  return rateLimit({
    windowMs,
    max,
    message: {
      success: false,
      error: message
    },
    standardHeaders: true,
    legacyHeaders: false,
  });
};

// Rate limits for different endpoints
const rateLimits = {
  general: createRateLimit(
    15 * 60 * 1000, // 15 minutes
    100, // limit each IP to 100 requests per windowMs
    'Too many requests from this IP, please try again later'
  ),

  expensive: createRateLimit(
    15 * 60 * 1000, // 15 minutes
    20, // limit each IP to 20 requests per windowMs for expensive operations
    'Too many expensive requests from this IP, please try again later'
  ),

  events: createRateLimit(
    60 * 1000, // 1 minute
    10, // limit each IP to 10 requests per minute for event queries
    'Too many event queries from this IP, please try again later'
  )
};

// Request logging middleware
const logRequest = (req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.originalUrl} - ${res.statusCode} - ${duration}ms`);
  });

  next();
};

// Error handling middleware
const errorHandler = (err, req, res, next) => {
  console.error('API Error:', err);

  // Handle different types of errors
  if (err.code === 'NETWORK_ERROR') {
    return res.status(503).json({
      success: false,
      error: 'Network error - please try again later'
    });
  }

  if (err.code === 'CALL_EXCEPTION') {
    return res.status(400).json({
      success: false,
      error: 'Smart contract call failed',
      details: err.reason || err.message
    });
  }

  if (err.code === 'INVALID_ARGUMENT') {
    return res.status(400).json({
      success: false,
      error: 'Invalid arguments provided',
      details: err.message
    });
  }

  // Default error response
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
};

// CORS middleware for cross-origin requests
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS ?
    process.env.ALLOWED_ORIGINS.split(',') :
    ['http://localhost:3000', 'http://localhost:3001'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true
};

// Security headers middleware
const securityHeaders = (req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
};

module.exports = {
  validateUserAddress,
  validateInvestmentId,
  validatePlanId,
  validateQuoteRequest,
  validateInvestmentPreparation,
  validatePagination,
  validateEventQuery,
  rateLimits,
  logRequest,
  errorHandler,
  corsOptions,
  securityHeaders,
  handleValidationErrors
};