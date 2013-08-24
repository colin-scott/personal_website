push:
	jekyll build
	scp _site/* rcs@login.eecs.berkeley.edu:~/public_html/
