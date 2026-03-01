# Node.js Backend - Quick Start Guide

## ✅ Installation Complete!

Your Node.js backend has been successfully created and tested. It provides **identical functionality** to the Ballerina backend.

## 🚀 Quick Start

### 1. Install Dependencies (First Time Only)

```bash
cd nodejs-backend
npm install
```

Or use the batch script:
```bash
setup-nodejs.bat
```

### 2. Start the Server

```bash
cd nodejs-backend
npm start
```

Or use the batch script:
```bash
start-nodejs-backend.bat
```

The server will start on **http://localhost:8080**

## 📝 What You Get

### Complete Backend API

All endpoints from the Ballerina backend, including:

- **Authentication** (register, login, profile, logout)
- **API Key Management** (create, list, update, delete)
- **Quota Management** (100 requests/month per API key)
- **Public APIs** (users, projects, analytics, content moderation)
- **Health Check** and documentation endpoints

### Database

- SQLite database automatically created at `nodejs-backend/database/userportal.db`
- Same schema as Ballerina backend
- Can share database with Ballerina backend (both use same structure)

### Configuration

Edit `nodejs-backend/.env` to customize:
- Port number
- JWT secret
- Database path
- CORS origins

## 🧪 Testing

Test the backend with PowerShell scripts:

```powershell
# Test authentication endpoints
.\test-auth.ps1

# Test API key management
.\test-apikeys.ps1

# Test public API endpoints
.\test-public-api.ps1
```

Or manually test the health endpoint:
```bash
curl http://localhost:8080/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "userportal-auth",
  "timestamp": "2026-03-01T10:08:35.362Z"
}
```

## 🔄 Switching Between Backends

The frontend works with both backends without any changes!

### To Use Node.js Backend:
1. Stop Ballerina backend if running (Ctrl+C)
2. Start Node.js backend: `npm start` or `start-nodejs-backend.bat`
3. Frontend automatically connects to http://localhost:8080

### To Use Ballerina Backend:
1. Stop Node.js backend if running (Ctrl+C)
2. Start Ballerina backend: `bal run` or `start-services.bat`
3. Frontend automatically connects to http://localhost:8080

**Note:** Only run ONE backend at a time since both use port 8080.

## 📂 Project Structure

```
nodejs-backend/
├── server.js              # Main Express server & startup
├── config.js              # Configuration management
├── database.js            # SQLite operations (users, tokens)
├── auth.js                # JWT token utilities
├── apikeys.js             # API key management
├── quota.js               # Usage quota tracking
├── middleware.js          # Authentication middleware
├── routes/
│   ├── auth.routes.js     # POST /auth/register, /auth/login, etc.
│   ├── apikeys.routes.js  # POST /apikeys, GET /apikeys, etc.
│   └── public.routes.js   # GET /users, /projects, etc.
├── database/
│   └── userportal.db      # SQLite database (auto-created)
├── package.json           # Dependencies
├── .env                   # Environment variables
└── README.md              # Full documentation
```

## 🎯 Key Features

✅ **Same API Endpoints** - Identical to Ballerina backend  
✅ **Same Database Schema** - SQLite with 3 tables  
✅ **JWT Authentication** - Secure token-based auth  
✅ **Password Hashing** - bcrypt for secure passwords  
✅ **API Key Management** - Max 3 keys per user  
✅ **Quota Tracking** - 100 requests/month per key  
✅ **Auto Quota Reset** - Resets on 1st of each month  
✅ **Token Revocation** - Secure logout  
✅ **CORS Support** - Configured for frontend  
✅ **Error Handling** - Comprehensive error responses  

## 💡 Development Tips

### Run in Development Mode (with auto-reload)
```bash
cd nodejs-backend
npm run dev
```

### View Database
```bash
.\view-database.bat
```

### Check for Errors
```bash
cd nodejs-backend
npm test
```

### Environment Variables
Create a `.env` file based on `.env.example`:
```env
PORT=8080
JWT_SECRET=your-secret-key-here
DB_PATH=./database/userportal.db
```

## 📚 Documentation

- **Full README**: `nodejs-backend/README.md`
- **API Documentation**: http://localhost:8080/api/docs
- **Backend Comparison**: `BACKEND-COMPARISON.md`
- **Main Project README**: Root `README.md`

## ✅ Verified Working

The Node.js backend has been tested and verified:
- ✅ Dependencies installed successfully
- ✅ Server starts without errors
- ✅ Database schema created automatically
- ✅ Health endpoint responds correctly
- ✅ All routes configured properly

## 🛠️ Troubleshooting

### Port 8080 Already in Use
If you see "EADDRINUSE" error:
1. Stop the Ballerina backend if running
2. Or change the port in `.env` file:
   ```env
   PORT=3001
   ```

### Module Not Found
Run `npm install` in the `nodejs-backend` directory

### Database Locked
Close any SQLite browser tools that might have the database open

## 🎉 Next Steps

1. **Keep using Ballerina** if you prefer, or
2. **Switch to Node.js** - everything will work the same!
3. **Start the frontend** to see the full application:
   ```bash
   cd userportal
   npm run dev
   ```

The choice is yours - both backends provide identical functionality!

---

**Need Help?**
- Check `nodejs-backend/README.md` for detailed documentation
- Compare backends in `BACKEND-COMPARISON.md`
- Test endpoints with the provided PowerShell scripts
