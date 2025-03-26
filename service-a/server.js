const express = require('express');
const { Pool } = require('pg'); // Import pg Pool
const cors = require('cors'); // Import cors
const app = express();
const port = 3001;

app.use(cors()); // Enable CORS for all origins

// Database connection configuration
// Reads values from environment variables injected by Kubernetes
const pool = new Pool({
  user: process.env.POSTGRES_USER, // Read from environment variable
  host: process.env.POSTGRES_HOST || 'postgres-db-service', // Read from env var or default to K8s service name
  database: process.env.POSTGRES_DB, // Read from environment variable
  password: process.env.POSTGRES_PASSWORD, // Read from environment variable
  port: process.env.POSTGRES_PORT || 5432, // Read from env var or default to 5432
});

// Function to initialize the database table
const initializeDb = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS service_a_data (
        id SERIAL PRIMARY KEY,
        message VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Database table "service_a_data" checked/created successfully.');
  } catch (err) {
    console.error('Error initializing database table:', err.stack);
    // Consider exiting if DB init fails, or implement retry logic
  }
};

// Initialize DB on startup and start server afterwards
const startServer = async () => {
  await initializeDb(); // Wait for DB init to complete

  app.get('/', async (req, res) => {
  // Check DB connection status
  try {
    const client = await pool.connect();
    res.send('Hello from Service A! Connected to Database.');
    client.release(); // Release the client back to the pool
  } catch (err) {
    res.status(500).send('Hello from Service A! Database connection error.');
    console.error('Database connection error on /:', err.stack);
  }
});

// Updated endpoint to interact with the database
app.get('/data', async (req, res) => {
  try {
    // Insert a new record
    const insertText = 'INSERT INTO service_a_data(message) VALUES($1)';
    const insertValues = [`Data requested at ${new Date().toISOString()}`];
    await pool.query(insertText, insertValues);

    // Retrieve all records
    const selectText = 'SELECT * FROM service_a_data ORDER BY created_at DESC';
    const { rows } = await pool.query(selectText);

    res.json(rows); // Return all records
  } catch (err) {
    console.error('Error executing query on /data:', err.stack);
    res.status(500).json({ error: 'Database query failed' });
  }
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Closing database pool...');
  await pool.end();
  console.log('Pool has ended');
  process.exit(0);
});

  // This is the correct place for app.listen, inside startServer
  app.listen(port, () => {
    console.log(`Service A listening at http://localhost:${port}`);
  });
};

startServer(); // Call the async function to start the server
