# 🛍️ ShopDeploy Frontend

<p align="center">
  <img src="https://img.shields.io/badge/React-18.x-61DAFB?style=for-the-badge&logo=react" alt="React"/>
  <img src="https://img.shields.io/badge/Vite-5.x-646CFF?style=for-the-badge&logo=vite" alt="Vite"/>
  <img src="https://img.shields.io/badge/Redux_Toolkit-2.x-764ABC?style=for-the-badge&logo=redux" alt="Redux"/>
  <img src="https://img.shields.io/badge/Tailwind_CSS-3.x-38B2AC?style=for-the-badge&logo=tailwind-css" alt="Tailwind"/>
  <img src="https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker" alt="Docker"/>
</p>

Modern, responsive e-commerce frontend application built with React, Vite, Redux Toolkit, and Tailwind CSS. Features a complete shopping experience with authentication, cart management, and admin dashboard.

---

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Running the Application](#-running-the-application)
- [Docker Deployment](#-docker-deployment)
- [Project Structure](#-project-structure)
- [Pages & Routes](#-pages--routes)
- [State Management](#-state-management)
- [Styling](#-styling)
- [Available Scripts](#-available-scripts)
- [Contributing](#-contributing)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎨 **Modern UI/UX** | Beautiful, responsive design with Tailwind CSS |
| 🔐 **Authentication** | JWT-based login/register with auto token refresh |
| 🛒 **Shopping Cart** | Full cart functionality with persistence |
| 📦 **Product Catalog** | Browse, search, filter products |
| 💳 **Checkout Flow** | Complete order placement process |
| 👤 **User Profile** | Order history and account management |
| 🛠️ **Admin Dashboard** | Product, order, and user management |
| 📱 **Responsive Design** | Mobile-first approach for all devices |
| 🔒 **Protected Routes** | Role-based access control |
| 🌐 **PWA Ready** | Progressive Web App capabilities |

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| React 18 | UI Library |
| Vite | Build tool & dev server |
| Redux Toolkit | State management |
| React Router | Client-side routing |
| Tailwind CSS | Utility-first styling |
| Axios | HTTP client |
| React Hot Toast | Notifications |
| React Icons | Icon library |

---

## 📋 Prerequisites

- **Node.js** v18 or higher
- **npm** v9 or higher
- **Backend API** running (see shopdeploy-backend)

---

## 🛠️ Installation

### 1. Navigate to Frontend Directory

```bash
cd shopdeploy-frontend
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

Update the environment variable:
```env
# API Configuration
VITE_API_URL=http://localhost:5000/api

# Optional: Analytics, etc.
VITE_GA_TRACKING_ID=your-google-analytics-id
```

---

## 🏃 Running the Application

### Development Mode

```bash
npm run dev
```

The application will start at `http://localhost:5173`

### Build for Production

```bash
npm run build
```

### Preview Production Build

```bash
npm run preview
```

---

## 🐳 Docker Deployment

### Build & Run Locally

```bash
# Build image
docker build -t shopdeploy-frontend:latest .

# Run container (uses nginx-unprivileged on port 8080)
docker run -d -p 8080:8080 shopdeploy-frontend:latest
```

### Build & Push to ECR

```bash
# Using the provided script
chmod +x scripts/deploy-frontend.sh
./scripts/deploy-frontend.sh

# Or manually
docker build -t shopdeploy-frontend:latest .
docker tag shopdeploy-frontend:latest <ECR_URL>/shopdeploy-frontend:latest
docker push <ECR_URL>/shopdeploy-frontend:latest
```

### Production Configuration

The Docker image uses **nginx-unprivileged** to serve the built React application as a non-root user (UID 101) with:
- Runs on port **8080** (non-privileged port)
- Gzip compression enabled
- Client-side routing support (SPA fallback)
- Security headers
- Optimized caching for static assets
- Non-root execution for enhanced security

### Kubernetes Health Probes

When deployed to Kubernetes, the frontend uses:

| Probe Type | Path | Port | Purpose |
|------------|------|------|----------|
| **Liveness** | `/` | 8080 | Check if Nginx is responding |
| **Readiness** | `/` | 8080 | Verify container is ready for traffic |

### Service Configuration

| Environment | Service Type | Port | Target Port |
|-------------|--------------|------|-------------|
| **Dev** | LoadBalancer | 80 | 8080 |
| **Staging** | LoadBalancer | 80 | 8080 |
| **Production** | LoadBalancer | 80 | 8080 |

---

## 🔄 CI/CD Pipeline

The frontend is built and deployed as part of the Jenkins pipeline:

| Stage | Description |
|-------|-------------|
| **Install Dependencies** | `npm ci` with caching |
| **Linting** | ESLint checks (mandatory) |
| **Unit Tests** | Jest with coverage (mandatory) |
| **SonarQube Analysis** | Code quality scan (gracefully skips if not configured) |
| **Docker Build** | Multi-stage Dockerfile (nginx-unprivileged) |
| **Security Scan** | Trivy vulnerability scan |
| **Push to ECR** | AWS ECR registry |
| **Helm Deploy** | Kubernetes deployment with LoadBalancer |

### Docker Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| **Base Image** | nginxinc/nginx-unprivileged:alpine | Non-root execution |
| **Container Port** | 8080 | Unprivileged port |
| **Service Port** | 80 | External access |
| **User ID** | 101 | nginx user |

--- 

## 📁 Project Structure

```
shopdeploy-frontend/
├── src/
│   ├── App.jsx               # Main React component
│   ├── main.jsx              # App entry point
│   ├── index.css             # Global Tailwind styles
│   ├── api/                  # Axios API clients
│   │   └── axios.js          # Configured Axios instance
│   ├── app/                  # Redux store configuration
│   │   └── store.js          # Redux store setup
│   ├── components/           # Reusable UI components
│   │   ├── Navbar.jsx        # Navigation bar
│   │   ├── Footer.jsx        # Footer component
│   │   ├── ProductCard.jsx   # Product card component
│   │   ├── ProtectedRoute.jsx # Auth route wrapper
│   │   └── AdminRoute.jsx    # Admin route wrapper
│   ├── features/             # Redux slices
│   │   ├── auth/             # Authentication state
│   │   ├── cart/             # Shopping cart state
│   │   ├── products/         # Product state
│   │   └── orders/           # Order state
│   ├── layouts/              # Page layout wrappers
│   ├── pages/                # Page components
│   │   ├── Home.jsx          # Landing page
│   │   ├── Products.jsx      # Product listing
│   │   ├── ProductDetails.jsx # Single product view
│   │   ├── Cart.jsx          # Shopping cart
│   │   ├── Checkout.jsx      # Checkout flow
│   │   ├── Orders.jsx        # Order history
│   │   ├── OrderDetails.jsx  # Single order view
│   │   ├── Profile.jsx       # User profile
│   │   ├── auth/             # Login, Register pages
│   │   └── admin/            # Admin dashboard pages
│   ├── routes/               # Route definitions
│   └── utils/                # Helper functions
├── scripts/
│   ├── deploy-frontend.sh    # Deploy script (Linux)
│   └── deploy-frontend.ps1   # Deploy script (Windows)
├── index.html                # HTML template
├── Dockerfile                # Multi-stage Docker (Nginx)
├── nginx.conf                # Nginx configuration
├── vite.config.js            # Vite build configuration
├── tailwind.config.js        # Tailwind CSS configuration
├── postcss.config.cjs        # PostCSS configuration
├── .eslintrc.cjs             # ESLint configuration
├── .env.example              # Environment template
├── .dockerignore             # Docker ignore rules
├── README.md                 # This file
└── package.json              # Dependencies & scripts
```

---

## 🎨 Pages & Routes

### Public Pages

| Route | Page | Description |
|-------|------|-------------|
| `/` | Home | Landing page with featured products |
| `/products` | Products | Product listing with filters |
| `/products/:id` | Product Detail | Individual product page |
| `/login` | Login | User authentication |
| `/register` | Register | New user registration |

### Protected Pages (User)

| Route | Page | Description |
|-------|------|-------------|
| `/cart` | Cart | Shopping cart management |
| `/checkout` | Checkout | Order placement |
| `/profile` | Profile | User profile & order history |
| `/orders` | Orders | Order history |

### Admin Pages

| Route | Page | Description |
|-------|------|-------------|
| `/admin` | Dashboard | Admin overview |
| `/admin/products` | Products | Product CRUD |
| `/admin/orders` | Orders | Order management |
| `/admin/users` | Users | User management |

---

## 🔐 Authentication

The app uses JWT tokens for authentication:

| Token | Storage | Purpose |
|-------|---------|---------|
| Access Token | localStorage | API requests |
| Refresh Token | localStorage | Token renewal |

**Features:**
- Automatic token refresh on expiration
- Protected routes with authentication checks
- Role-based access (User/Admin)
- Persistent login across sessions

---

## 🎯 State Management

Redux Toolkit slices:

| Slice | Purpose |
|-------|---------|
| `authSlice` | User authentication, login state |
| `productSlice` | Product data, filters, search |
| `cartSlice` | Shopping cart items, totals |
| `orderSlice` | Order history, checkout |

---

## 🎨 Styling

- **Tailwind CSS** - Utility-first CSS framework
- **Mobile-first** - Responsive design approach
- **Dark Mode** - Theme support (optional)
- **Custom Components** - Consistent design system

### Color Palette

```css
Primary:   #3B82F6 (Blue)
Secondary: #10B981 (Green)
Accent:    #F59E0B (Amber)
Error:     #EF4444 (Red)
```

---

## 📦 Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| react | ^18.x | UI library |
| react-redux | ^9.x | State management |
| @reduxjs/toolkit | ^2.x | Redux utilities |
| react-router-dom | ^6.x | Routing |
| axios | ^1.x | HTTP client |
| tailwindcss | ^3.x | CSS framework |
| react-hot-toast | ^2.x | Notifications |
| react-icons | ^5.x | Icon library |

---

## 🔧 Available Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |
| `npm run lint` | Run ESLint |

---

## 🚀 Deployment

### Build the Application

```bash
npm run build
```

The build output will be in the `dist/` directory, ready to deploy to:
- **AWS EKS** (via Jenkins pipeline)
- **AWS S3 + CloudFront**
- **Vercel**
- **Netlify**
- **Nginx (Docker)**

### Deploy to EKS (via Jenkins)

```bash
# Automatic deployment via Jenkins pipeline
# 1. Push code to GitHub
# 2. Jenkins automatically builds and deploys
# 3. Or manually trigger in Jenkins UI

# Manual Helm deployment
helm upgrade --install shopdeploy-frontend ./helm/frontend \
  --namespace shopdeploy \
  --set image.repository=<ECR_URL>/shopdeploy-prod-frontend \
  --set image.tag=latest
```

### Environment-specific Builds

```bash
# Development
VITE_API_URL=http://localhost:5000/api npm run build

# Production
VITE_API_URL=https://api.shopdeploy.com/api npm run build
```

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
