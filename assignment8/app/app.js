const express = require('express');
const app = express();

// Elastic Beanstalk sets PORT via env variable; default to 8080 for local testing
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>EB Sample App</title></head>
      <body style="font-family: Arial, sans-serif; text-align:center; margin-top: 80px;">
        <h1>🚀 Hello from AWS Elastic Beanstalk!</h1>
        <p>This sample Node.js application was deployed using Terraform.</p>
        <p>Server time: ${new Date().toISOString()}</p>
      </body>
    </html>
  `);
});

// Simple health check endpoint used by the EB load balancer
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(port, () => {
  console.log(`App listening on port ${port}`);
});
