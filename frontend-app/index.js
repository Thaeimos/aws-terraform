import express from 'express';
import fetch from 'node-fetch';

const PORT = process.env.PORT || 3000

let app = express()
const APPLICATION_LOAD_BALANCER = process.env.APPLICATION_LOAD_BALANCER;

app.get('/', async (req, res) => {
  fetch('http://169.254.169.254/latest/meta-data/hostname').then(async(response) => {
    const hostname = await response.text();
    console.log("Received a / request!");
    res.write(`Hello from ${hostname}\n`)
    res.write(`The loadbalancer for the backend is ${process.env.APPLICATION_LOAD_BALANCER}\n`)
    res.write(`The environment value is ${process.env.ENVIRONMENT}\n`)
    res.end()
    res.send()
  })
})

app.get('/init', async (req, res) => {
  fetch(`http://${process.env.APPLICATION_LOAD_BALANCER}/init`).then(async (response) => {
    const data = await response.json();
    console.log("Received a /init request!");
    res.send(data)
  })
})

app.get('/users', async (req, res) => {
  fetch(`http://${process.env.APPLICATION_LOAD_BALANCER}/users`).then(async (response) => {
    const data = await response.json();
    console.log("Received a /users request!");
    res.send(data)
  })
})

// Custom 404 route not found handler
app.use((req, res) => {
  res.status(404).send('404 not found')
})

app.listen(PORT, () => {
  console.log(`Listening on PORT ${PORT}`);
})

