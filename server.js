const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.resolve(__dirname, 'notifications-channels-firebase-adminsdk-z3g11-972809f12c.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://notifications-channels-default-rtdb.firebaseio.com"
});

const app = express();
app.use(bodyParser.json()); // to parse JSON request bodies

// Endpoint to handle push notification request
app.post('/send-notification', (req, res) => {
  const { title, body, topic } = req.body;

  const message = {
    notification: {
      title: title,
      body: body,
    },
    topic: topic,
  };

  admin.messaging()
    .send(message)
    .then((response) => {
      console.log('Successfully sent message:', response);
      res.status(200).send('Message sent successfully');
    })
    .catch((error) => {
      console.log('Error sending message:', error);
      res.status(500).send('Error sending message');
    });
});

const port = 3000;
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

