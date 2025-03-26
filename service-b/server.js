const express = require('express');
const cors = require('cors'); // Import cors
const app = express();
const port = 3002; // Port for Service B

app.use(cors()); // Enable CORS for all origins

app.get('/', (req, res) => {
  res.send('Hello from Service B!');
});

// New endpoint to return some data
app.get('/data', (req, res) => {
  res.json({ source: 'Service B', value: Math.random() * 100 });
});

app.listen(port, () => {
  console.log(`Service B listening at http://localhost:${port}`);
});
