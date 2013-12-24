push:
	jekyll build
	scp build/*html build/*bib rcs@login.eecs.berkeley.edu:~/public_html/
