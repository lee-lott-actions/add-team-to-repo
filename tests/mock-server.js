const express = require('express');
const app = express();
app.use(express.json());

app.put('/orgs/:owner/teams/:team_slug/repos/:owner/:repo_name', (req, res) => {
  console.log(`Mock intercepted: PUT /orgs/${req.params.owner}/teams/${req.params.team_slug}/repos/${req.params.owner}/${req.params.repo_name}`);
  console.log('Request body:', JSON.stringify(req.body));
  console.log('Request headers:', JSON.stringify(req.headers));

  // Validate the request body
  if (!req.body.permission || typeof req.body.permission !== 'string') {
    return res.status(400).json({ message: 'Invalid request: permission must be a non-empty string' });
  }

  // Simulate response based on parameters
  if (
    req.params.owner === 'test-owner' &&
    req.params.team_slug === 'test-team' &&
    req.params.repo_name === 'test-repo'
  ) {
    // Simulate successful response (HTTP 204 No Content)
    res.status(204).send();
  } else {
    // Simulate non-existent team or repository
    res.status(404).json({ message: 'Not Found' });
  }
});

app.listen(3000, () => {
  console.log('Mock server listening on http://127.0.0.1:3000...');
});
