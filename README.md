# GitHub Starstruck

This is a simple Ruby script that uses the
[GitHub GraphQL API](https://developer.github.com/v4/)
to get a sorted list of GitHub users based on how many repositories
they've starred. You must provide a
[personal GitHub access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)
and a file that has GitHub user names, either separated by spaces or
on separate lines. It creates a JSON file with the requested users
and how many stars they have.

## How to Use

```bash
echo "cheshire137 defunkt" > users.txt
ruby gh-starstruck.rb YOUR_ACCESS_TOKEN users.txt
cat users.txt
```
