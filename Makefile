edit::
	vim $$(find content | peco)

serve::
	hugo serve -D

build::
	hugo 

theme-update::
	git submodule update --remote --merge 
