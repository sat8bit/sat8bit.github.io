l::
	hugo new logs/daily-$$(date +%Y-%m-%d).md

serve::
	hugo serve -D

build::
	hugo 

theme-update::
	git submodule update --remote --merge 
