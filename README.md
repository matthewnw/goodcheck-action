# Goodcheck PR Review

GitHub Action to analyze pull request changes using Goodcheck and post inline comments.

https://sider.github.io/goodcheck/docs/getstarted

## Usage

```yaml
- uses: matthewnw/goodcheck-pr-review@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
```


## Rules

Add a new file in the root called `goodcheck.yml`

Then add rules for your standards (Docs: https://sider.github.io/goodcheck/docs/configuration)

```yaml
exclude:
    - node_modules
    - vendor
    - storage

severity:
  allow: [blocking,non-blocking]
  required: true

rules:
  # id, pattern, message are required attributes.]

  - id: php-debug-code
    severity: blocking
    pattern:
      - regexp: (\s|\->)(dd|dump)\(.*\);
    message: Did you mean to leave this here?
    glob:
      - "**/*.php"
```