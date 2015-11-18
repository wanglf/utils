.PHONY: all clean slide

menu_dir = build/jekyll/menu
jekyll_dir = build/jekyll
reveal_dir = $(abspath build/reveal)

menu = menu
posts = algorithm editor network kernel language leaf linux tools sa
sas = sa
slide = linux

posts:
	puborg -n -j $(menu) -o $(menu_dir)
	puborg -p $(posts)

latex:
	puborg -l $(posts)

beamer:
	cd slide && puborg -l $(slide)

slide:
	cd slide && puborg -o $(reveal_dir) -r $(slide)

all: slide posts latex beamer

clean:
	puborg -c $(menu) $(posts)
	cd slide && puborg -c $(slide)
