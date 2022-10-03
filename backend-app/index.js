import express from 'express';
import mysql from 'mysql';

const PORT = process.env.PORT || 3000

let app = express()

app.get('/', async (req, res) => {
  res.send({ message: "Hello world from the backend" })
})

app.get('/init', async (req, res) => {
  console.log("Received a /init request!");
  console.log("Debug secrest:");
  console.log(`Value of Hostname is ${process.env.RDS_HOSTNAME}`);
  console.log(`Value of Username is ${process.env.RDS_USERNAME}`);
  console.log(`Value of Password is ${process.env.RDS_PASSWORD}`);
  console.log(`Value of Port is ${process.env.RDS_PORT}`);
  console.log(`Value of DB Name is ${process.env.RDS_DB_NAME}`);
  try {
    const connection = mysql.createConnection({
      host: process.env.RDS_HOSTNAME,
      user: process.env.RDS_USERNAME,
      password: process.env.RDS_PASSWORD,
      port: process.env.RDS_PORT,
      db_name: process.env.RDS_DB_NAME
    });
    console.log("POST create connection");
    connection.connect(error => {
      if (error) throw error;
      console.log("Successfully connected to the database.");
    });
    console.log("POST connect");
    connection.query(`use ${process.env.RDS_DB_NAME};`)
    console.log("POST query");

    connection.query('CREATE TABLE IF NOT EXISTS users (id INT(5) NOT NULL AUTO_INCREMENT PRIMARY KEY, lastname VARCHAR(40), firstname VARCHAR(40), email VARCHAR(30));');
    console.log("POST query 01");
    connection.query('INSERT INTO users (lastname, firstname, email) VALUES ( "Tony", "Sam", "tonysam@whatever.com"), ( "Doe", "John", "john.doe@whatever.com" );');
    console.log("POST query 02");
    res.send({ message: "init step done" })
  } catch (error) {
    console.log(`Error doing the init DB: ${error}`);
    res.send({ message: "init step not OK :(" })
  }
})

app.get('/users', async (req, res) => {
  console.log("Received a /users request!");
  try {
    const connection = mysql.createConnection({
      host: process.env.RDS_HOSTNAME,
      user: process.env.RDS_USERNAME,
      password: process.env.RDS_PASSWORD,
      port: process.env.RDS_PORT,
      db_name: process.env.RDS_DB_NAME
    });
    connection.connect()
    connection.query(`use ${process.env.RDS_DB_NAME};`)
  } catch (error) {
    console.log(`Error creating the DB connection: ${error}`);
  }

  connection.query('SELECT * from users', function (error, results) {
    if (error) throw error;
    res.send(results)
  });
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
