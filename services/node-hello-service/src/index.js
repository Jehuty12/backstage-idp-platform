const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello from node-hello-service', pod: process.env.HOSTNAME || 'unknown' });
});

app.listen(port, () => {
  console.log(`node-hello-service listening on port ${port}`);
});
