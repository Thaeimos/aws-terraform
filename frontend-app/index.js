import express from 'express';
import fetch from 'node-fetch';
import aws from 'aws-sdk'
import AWSXRay from 'aws-xray-sdk'
import http from 'http'

// Capture all AWS clients we create
const AWS = AWSXRay.captureAWS(aws);
AWS.config.update({region: process.env.DEFAULT_AWS_REGION || 'eu-west-2'});

// Capture all outgoing https requests
AWSXRay.captureHTTPsGlobal(http);

const PORT = process.env.PORT || 3000

let app = express()

AWSXRay.config([AWSXRay.plugins.ECSPlugin]);
AWSXRay.middleware.enableDynamicNaming();
app.use(AWSXRay.express.openSegment('Frontend'));

app.get('/', async (req, res) => {
  const seg = AWSXRay.getSegment();
  const sub = seg.addNewSubsegment('customSubsegment');
  sub.addAnnotation('service', 'meta-data-service');
  fetch('http://169.254.169.254/latest/meta-data/hostname').then(async(response) => {
    const hostname = await response.text();
    // console.log("Received a / request!");
    res.write(`Hello from ${hostname}\n`)
    res.write(`The loadbalancer for the backend is ${process.env.APPLICATION_LOAD_BALANCER}\n`)
    res.write(`The environment value is ${process.env.ENVIRONMENT}\n`)
    res.write(`The secret value is ${process.env.Test_v}\n`)
    res.end()
    sub.close();
    res.send()
  }).catch(error => {
    console.log('There is some error - ' + error);
  });
})

app.get('/test-back', async (req, res) => {
  const seg = AWSXRay.getSegment();
  const sub = seg.addNewSubsegment('customSubsegment');
  sub.addAnnotation('service', 'backend-service');
  fetch(`http://${process.env.APPLICATION_LOAD_BALANCER}/test-back`).then(async (response) => {
    console.log("Received a /test-back request!");
    const data = await response.json();
    console.log(`Received a /test-back response: ${data}`);

    sub.close();
    res.send(data)
  }).catch(error => {
    console.log('There is some error - ' + error);
  });
})

app.get('/init', async (req, res) => {
  const seg = AWSXRay.getSegment();
  const sub = seg.addNewSubsegment('customSubsegment');
  sub.addAnnotation('service', 'backend-service');
  fetch(`http://${process.env.APPLICATION_LOAD_BALANCER}/init`).then(async (response) => {
    console.log("Received a /init request!");
    const data = await response.json();

    sub.close();
    res.send(data)
  }).catch(error => {
    console.log('There is some error - ' + error);
  });
})

app.get('/users', async (req, res) => {
  const seg = AWSXRay.getSegment();
  const sub = seg.addNewSubsegment('customSubsegment');
  sub.addAnnotation('service', 'backend-service');
  fetch(`http://${process.env.APPLICATION_LOAD_BALANCER}/users`).then(async (response) => {
    console.log("Received a /users request!");
    const data = await response.json();

    sub.close();
    res.send(data)
  }).catch(error => {
    console.log('There is some error - ' + error);
  });
})

// Health check
app.get('/healthcheck', async (req, res) => {
  res.send("OK")
})

// Custom 500
app.get('/500', async (req, res) => {
  res.status(500).send('500 internal server error')
})

// Custom 404 route not found handler
app.use((req, res) => {
  res.status(404).send('404 not found')
})

app.use(AWSXRay.express.closeSegment());

app.listen(PORT, () => {
  console.log(`Listening on PORT ${PORT}`);
})

