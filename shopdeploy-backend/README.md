# 🚀 ShopDeploy Backend API

<p align="center">
  <img src="https://img.shields.io/badge/Node.js-18.x-339933?style=for-the-badge&logo=node.js" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Express-4.x-000000?style=for-the-badge&logo=express" alt="Express"/>
  <img src="https://img.shields.io/badge/MongoDB-8.x-47A248?style=for-the-badge&logo=mongodb" alt="MongoDB"/>
  <img src="https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker" alt="Docker"/>
</p>

Production-ready E-Commerce REST API built with Node.js, Express, and MongoDB. Features JWT authentication, role-based access control, and Stripe payment integration.

---

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Running the Application](#-running-the-application)
- [Docker Deployment](#-docker-deployment)
- [API Documentation](#-api-documentation)
- [Database Models](#-database-models)
- [Authentication](#-authentication)
- [Project Structure](#-project-structure)
- [Testing](#-testing)
- [Contributing](#-contributing)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔐 **Authentication** | JWT with Access & Refresh Tokens |
| 👥 **User Roles** | Customer & Admin role-based access |
| 📦 **Products** | Full CRUD with image upload |
| 🗂️ **Categories** | Product categorization |
| 🛒 **Shopping Cart** | Persistent cart in database |
| 📋 **Orders** | Complete checkout flow |
| 💳 **Payments** | Stripe integration |
| 📁 **File Upload** | Local storage for images |
| ❤️ **Health Checks** | `/api/health/health` (liveness) & `/api/health/ready` (readiness) |

### Service Configuration

| Environment | Service Type | Port | Target Port |
|-------------|--------------|------|-------------|
| **Dev** | LoadBalancer | 5000 | 5000 |
| **Staging** | LoadBalancer | 5000 | 5000 |
| **Production** | LoadBalancer | 5000 | 5000 |

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| Node.js 18 | JavaScript runtime |
| Express.js | Web framework |
| MongoDB | NoSQL database |
| Mongoose | MongoDB ODM |
| JWT | Authentication tokens |
| bcryptjs | Password hashing |
| multer | File uploads |
| Stripe | Payment processing |
| cors | Cross-origin requests |
| helmet | Security headers |

---

## 📋 Prerequisites

- **Node.js** v18 or higher
- **MongoDB** v4.4 or higher (local or Atlas)
- **npm** v9 or higher
- **Stripe account** (optional, for payments)

## 🛠️ Installation

### 1. Clone & Navigate

```bash
cd shopdeploy-backend
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Setup

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Update the following variables in `.env`:
```env
# Server Configuration
PORT=5000
NODE_ENV=development

# MongoDB Connection
MONGODB_URI=mongodb://localhost:27017/shopdeploy

# JWT Secrets (generate strong random secrets)
JWT_ACCESS_SECRET=your_super_secure_access_token_secret_min_32_chars
JWT_REFRESH_SECRET=your_super_secure_refresh_token_secret_min_32_chars
JWT_ACCESS_EXPIRE=15m
JWT_REFRESH_EXPIRE=7d

# Stripe (Optional - for payments)
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:5173

# File Upload
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads
```

### 4. Create Uploads Directory

```bash
mkdir uploads
```

---

## 🏃 Running the Application

### Development Mode (with hot reload)

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

### With Docker

```bash
# Build image
docker build -t shopdeploy-backend:latest .

# Run container
docker run -d -p 5000:5000 --env-file .env shopdeploy-backend:latest
```

The server will start at `http://localhost:5000`

### Health Check

```bash
# Liveness probe - checks if server is running
curl http://localhost:5000/api/health/health
# Response: { "status": "OK", "timestamp": "...", "uptime": 123.45, "environment": "development" }

# Readiness probe - checks if server is ready to accept traffic
curl http://localhost:5000/api/health/ready
# Response: { "status": "ready", "timestamp": "..." }
```

These endpoints are used by Kubernetes for:
- **Liveness Probe**: Restart container if unhealthy
- **Readiness Probe**: Remove from load balancer if not ready

---

## 🐳 Docker Deployment

### Build & Push to ECR

```bash
# Using the provided script
chmod +x scripts/build-and-push.sh
./scripts/build-and-push.sh

# Or manually
docker build -t shopdeploy-backend:latest .
docker tag shopdeploy-backend:latest <ECR_URL>/shopdeploy-backend:latest
docker push <ECR_URL>/shopdeploy-backend:latest
```

### Multi-stage Dockerfile

The included Dockerfile uses multi-stage builds for optimized production images:
- Stage 1: Install dependencies
- Stage 2: Create minimal production image
- Final image: ~200MB with only production dependencies

---

## 📚 API Documentation

### Base URL

```
Development: http://localhost:5000/api
Production:  https://api.shopdeploy.com/api
```

### Authentication Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| `POST` | `/auth/register` | Register new user | Public |
| `POST` | `/auth/login` | Login user | Public |
| `POST` | `/auth/refresh-token` | Refresh access token | Public |
| `POST` | `/auth/logout` | Logout user | Private |
| `GET` | `/auth/me` | Get current user | Private |

### Product Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| `GET` | `/products` | Get all products (with filters) | Public |
| `GET` | `/products/:id` | Get single product | Public |
| `POST` | `/products` | Create product | Admin |
| `PUT` | `/products/:id` | Update product | Admin |
| `DELETE` | `/products/:id` | Delete product | Admin |

**Query Parameters for GET /products:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 10)
- `category` - Filter by category ID
- `search` - Search in name/description
- `sort` - Sort field (price, createdAt)

### Category Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| `GET` | `/categories` | Get all categories | Public |
| `GET` | `/categories/:id` | Get single category | Public |
| `POST` | `/categories` | Create category | Admin |
| `PUT` | `/categories/:id` | Update category | Admin |
| `DELETE` | `/categories/:id` | Delete category | Admin |

### Cart Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| `GET` | `/cart` | Get user cart | Private |
| `POST` | `/cart` | Add item to cart | Private |
| `PUT` | `/cart/:itemId` | Update cart item quantity | Private |
| `DELETE` | `/cart/:itemId` | Remove item from cart | Private |
| `DELETE` | `/cart` | Clear cart | Private |

### Order Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| `POST` | `/orders` | Create new order | Private |
| `GET` | `/orders` | Get user orders | Private |
| `GET` | `/orders/all` | Get all orders | Admin |
| `GET` | `/orders/:id` | Get single order | Private |
| `PUT` | `/orders/:id/status` | Update order status | Admin |

### Health Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| `GET` | `/health/health` | Liveness check | Public |
| `GET` | `/health/ready` | Readiness check | Public |

---

## 🗄️ Database Models

| Model | Description |
|-------|-------------|
| **User** | User accounts with authentication, roles |
| **Product** | Product catalog with images, pricing |
| **Category** | Product categorization |
| **Cart** | Shopping cart with items |
| **Order** | Customer orders with status tracking |

---

## 🔐 Authentication

This API uses JWT (JSON Web Tokens) with two-token strategy:

| Token Type | Expiry | Purpose |
|------------|--------|---------|
| Access Token | 15 minutes | API requests |
| Refresh Token | 7 days | Get new access tokens |

**Token Delivery Methods:**
- Authorization header: `Authorization: Bearer <token>`
- HTTP-only cookies (recommended for security)

**Example Request:**
```bash
curl -X GET http://localhost:5000/api/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 📦 Project Structure

```
shopdeploy-backend/
├── src/
│   ├── app.js               # Express app configuration
│   ├── server.js            # Server entry point (port 5000)
│   ├── config/
│   │   └── db.js            # MongoDB connection
│   ├── controllers/
│   │   ├── authController.js     # Authentication logic
│   │   ├── productController.js  # Product CRUD
│   │   ├── categoryController.js # Category CRUD
│   │   ├── cartController.js     # Cart operations
│   │   └── orderController.js    # Order management
│   ├── middleware/
│   │   ├── auth.js          # JWT authentication
│   │   ├── admin.js         # Admin role check
│   │   └── errorHandler.js  # Error handling
│   ├── models/
│   │   ├── User.js          # User schema (auth, roles)
│   │   ├── Product.js       # Product schema
│   │   ├── Category.js      # Category schema
│   │   ├── Cart.js          # Shopping cart schema
│   │   └── Order.js         # Order schema
│   ├── routes/
│   │   ├── authRoutes.js    # /api/auth/*
│   │   ├── productRoutes.js # /api/products/*
│   │   ├── categoryRoutes.js # /api/categories/*
│   │   ├── cartRoutes.js    # /api/cart/*
│   │   ├── orderRoutes.js   # /api/orders/*
│   │   └── healthRoutes.js  # /api/health/* (liveness/readiness)
│   ├── services/            # Business logic layer
│   ├── scripts/             # Database seed scripts
│   └── utils/               # Helper functions
├── scripts/
│   ├── build-and-push.sh    # Docker build (Linux)
│   └── build-and-push.ps1   # Docker build (Windows)
├── Dockerfile               # Multi-stage Docker image
├── .env.example             # Environment template
├── .dockerignore            # Docker ignore rules
├── README.md                # This file
└── package.json             # Dependencies & scripts
```

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- --grep "auth"
```

### API Testing with cURL

```bash
# Register a new user
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get products
curl http://localhost:5000/api/products
```

---

## 🔧 Available Scripts

| Script | Description |
|--------|-------------|
| `npm start` | Start production server |
| `npm run dev` | Start development server (nodemon) |
| `npm test` | Run tests |
| `npm run lint` | Run ESLint |

---

## 🔄 CI/CD Pipeline

The backend is automatically built and deployed via Jenkins:

| Stage | Description |
|-------|-------------|
| **Install Dependencies** | `npm ci` with caching |
| **Linting** | ESLint checks (mandatory) |
| **Unit Tests** | Jest with coverage (mandatory) |
| **SonarQube Analysis** | Code quality scan (gracefully skips if not configured) |
| **Docker Build** | Multi-stage Dockerfile |
| **Security Scan** | Trivy vulnerability scan (HIGH/CRITICAL) |
| **Push to ECR** | AWS ECR registry with immutable tags |
| **Helm Deploy** | Kubernetes deployment with LoadBalancer |

### Kubernetes Deployment

```bash
# Automatic via Jenkins (recommended)
# Push to GitHub → Jenkins deploys to EKS

# Manual Helm deployment
helm upgrade --install shopdeploy-backend ./helm/backend \
  --namespace shopdeploy \
  -f ./helm/backend/values-dev.yaml \
  --set image.repository=<ECR_URL>/shopdeploy-prod-backend \
  --set image.tag=latest

# Check pod status
kubectl get pods -n shopdeploy -l app=shopdeploy-backend

# Get LoadBalancer URL
kubectl get svc shopdeploy-backend -n shopdeploy
```

### Health Probes (Kubernetes)

| Probe | Endpoint | Purpose |
|-------|----------|----------|
| Liveness | `/api/health/health` | Restart if unhealthy |
| Readiness | `/api/health/ready` | Remove from LB if not ready |
| Startup | `/api/health/ready` | Initial startup check |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

---

## 📝 License

ISC License

---

## 👥 Author

**ShopDeploy Team**

---

<p align="center">
  <b>Part of the ShopDeploy E-Commerce Platform</b>
</p>
