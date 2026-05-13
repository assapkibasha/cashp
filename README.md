# cashguard

CashGuard personal finance MVP.

## Running locally

The Flutter app uses the API server for sign in and account creation. If create account shows `Could not reach the CashGuard API at http://127.0.0.1:8080`, the server is not running or it failed to start.

1. Create `server/.env` from `server/.env.example`.
2. Set `DATABASE_URL` to a MySQL connection string.
3. Set `JWT_SECRET` to a random value with at least 32 characters.
4. Run the database migration:

```powershell
cd server
npm run migrate
```

5. Start the API:

```powershell
npm start
```

6. Check the API is reachable:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

It should return:

```json
{
  "ok": true
}
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
