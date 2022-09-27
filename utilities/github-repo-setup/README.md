# Description
Steps to configure the Github's repositories the way we need, with the variables and secrets needed.


# Make this work
We provide an example of how the file for the secrets should be. Just use the command below with the repository name, after getting your Github CLI authenticated.

```bash
cd utilities/github-repo-setup
gh auth login
REPO="Thaeimos/aws-terraform"
gh secret set -f secrets/repo.secrets --repo $REPO
```

# Test all is OK
```bash
gh secret list --repo $REPO
    AWS_ACCESS_KEY_ID      Updated 2022-09-27
    AWS_REGION             Updated 2022-09-27
    AWS_SECRET_ACCESS_KEY  Updated 2022-09-27
```