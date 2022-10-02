import express from 'express';
import fetch from 'node-fetch';
import mysql from 'mysql';

const PORT = process.env.PORT || 3000
// const connection = mysql.createConnection({
//   host: process.env.RDS_HOSTNAME,
//   user: process.env.RDS_USERNAME,
//   password: process.env.RDS_PASSWORD,
//   port: process.env.RDS_PORT,
//   db_name: process.env.RDS_DB_NAME
// });
// connection.connect()
// connection.query(`use ${process.env.RDS_DB_NAME};`)

let app = express()
const APPLICATION_LOAD_BALANCER = process.env.APPLICATION_LOAD_BALANCER;

app.get('/', async (req, res) => {
  res.send({ message: "Hello world from the backend" })
})

app.get('/init', async (req, res) => {
  console.log("Received a /init request!");
  // connection.query('CREATE TABLE IF NOT EXISTS users (id INT(5) NOT NULL AUTO_INCREMENT PRIMARY KEY, lastname VARCHAR(40), firstname VARCHAR(40), email VARCHAR(30));');
  // connection.query('INSERT INTO users (lastname, firstname, email) VALUES ( "Tony", "Sam", "tonysam@whatever.com"), ( "Doe", "John", "john.doe@whatever.com" );');
  res.send({ message: "init step done" })
})

app.get('/users', async (req, res) => {
  console.log("Received a /users request!");
  // connection.query('SELECT * from users', function (error, results) {
  //   if (error) throw error;
  //   res.send(results)
  // });
})

app.get('/test-back', async (req, res) => {
  console.log("Received a /test-back request!");
  res.send({ message: "Hello world from the backend - Test OK!" })
})

// Health check
app.get('/healthcheck', async (req, res) => {
  res.send({ message: "OK" })
})

// Custom 404 route not found handler
app.use((req, res) => {
  res.status(404).send({ message: "404 not found" })
})

app.listen(PORT, () => {
  console.log(`Listening on PORT ${PORT}`);
})
