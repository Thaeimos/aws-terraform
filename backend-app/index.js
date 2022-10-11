import express from 'express';
import mysql from 'mysql';

const PORT = process.env.PORT || 3000

let app = express()

app.get('/', async (req, res) => {
  res.send({ message: "Hello world from the backend" })
})

app.get('/init', async (req, res) => {
  console.log("Received a /init request!");

  try {
    let connection = mysql.createConnection({
      host: process.env.RDS_HOSTNAME,
      user: process.env.RDS_USERNAME,
      password: process.env.RDS_PASSWORD,
      port: process.env.RDS_PORT,
      database: process.env.RDS_DB_NAME
    });
    console.log("POST create connection");
  
    connection.connect(error => {
      if (error) throw error;
      console.log("Successfully connected to the database.");
    });

    console.log("PRE create table");
    let createTodos = `CREATE TABLE IF NOT EXISTS users (
        id INT(5) NOT NULL AUTO_INCREMENT PRIMARY KEY, 
        lastname VARCHAR(40), 
        firstname VARCHAR(40), 
        email VARCHAR(30)
      );`;

    connection.query(createTodos, function(err, results, fields) {
      if (err) {
        console.log(err.message);
      }
    });
    console.log("POST create table");

    console.log("PRE insert table");
    let sql = `INSERT INTO users (lastname, firstname, email) 
      VALUES ( "Tony", "Sam", "tonysam@whatever.com"), ( "Doe", "John", "john.doe@whatever.com" 
    );`;

    connection.query(sql, function(err, results, fields) {
      if (err) {
        console.log(err.message);
      }
    });
    console.log("POST insert table");

    connection.end(function(err) {
      if (err) {
        return console.log(err.message);
      }
    });
    res.send({ message: "init step done" })

  } catch (error) {
      console.log(`Error doing the init DB: ${error}`);
      res.send({ message: "init step not OK :(" })
  }
})

app.get('/users', async (req, res) => {
  console.log("Received a /users request!");

  try {
    let connection = mysql.createConnection({
      host: process.env.RDS_HOSTNAME,
      user: process.env.RDS_USERNAME,
      password: process.env.RDS_PASSWORD,
      port: process.env.RDS_PORT,
      database: process.env.RDS_DB_NAME
    });
    console.log("POST create connection");
  
    connection.connect(error => {
      if (error) throw error;
      console.log("Successfully connected to the database.");
    });

    connection.query('SELECT * from users', function (error, results) {
      if (error) throw error;
      res.json(results)
    });
  } catch (error) {
    console.log(`Error doing the querying for users: ${error}`);
    res.send({ message: "User query not OK :(" })
}
})

app.get('/test-back', async (req, res) => {
  console.log("Received a /test-back request!");
  res.send({ message: "Hello world from the backend - Test OK!" })
})

// Health check
app.get('/healthcheck', async (req, res) => {
  res.send({ message: "OK" })
})

// Custom 500 to test alarms
app.get('/500', async (req, res) => {
  res.status(500).send({ message: "500 Internal Server Error" })
})

// Custom 404 route not found handler
app.use((req, res) => {
  res.status(404).send({ message: "404 not found" })
})

app.listen(PORT, () => {
  console.log(`Listening on PORT ${PORT}`);
})
