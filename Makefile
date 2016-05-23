push:
	jekyll build
	scp _site/*html _site/*bib rcs@login.eecs.berkeley.edu:~/public_html/

test:
	jekyll build
	open -a Google\ Chrome _site/index.html
