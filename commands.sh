# Commands for administrating the blog
# Source this in your .zshrc file or similar

# Build and deploy
export BLOG_DIR="/Users/ragranat/personal/ronenagranat"
alias blogsync="cd $BLOG_DIR && JEKYLL_ENV=production bundle exec jekyll b && cd _site && aws s3 sync . s3://ronenagranat.com/ && cd -"
alias bloglocal="cd $BLOG_DIR && bundle exec jekyll serve"

