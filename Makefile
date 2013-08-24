push:
	jekyll build
	scp _site/*html _site/*bib rcs@login.eecs.berkeley.edu:~/public_html/
