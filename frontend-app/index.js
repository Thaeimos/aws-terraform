const express = require('express')
var child_process = require('child_process');
const app = express()
const port = 3000

function runCmd(cmd)
{
  var resp = child_process.execSync(cmd);
  var result = resp.toString('UTF8');
  return result;
}

var cmd = "curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone";  
var zone = runCmd(cmd);

app.get('/', (req, res) => res.send(`Hello World from ${zone}!`))

app.listen(port, () => console.log(`Example app listening on port ${port}!`))

