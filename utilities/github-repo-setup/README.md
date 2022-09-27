# Description
Steps to configure the Github's repositories the way we need, with the variables and secrets needed.


# Make this work
We provide an example of how the file for the secrets should be. Just use the command below with the repository name, after getting your Github CLI authenticated.

```bash
gh auth login
REPO="aws-terraform"
gh secret set -f secrets/repo.secrets --repo $REPO
```

# Test all is OK
```bash
# Nothing yet
```