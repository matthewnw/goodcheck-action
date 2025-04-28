# Goodcheck PR Review

GitHub Action to analyze pull request changes using Goodcheck and post inline comments.

https://sider.github.io/goodcheck/docs/getstarted

## Usage

```yaml
- uses: matthewnw/goodcheck-pr-review@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}