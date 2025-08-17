l::
	hugo new logs/daily-$$(date +%Y-%m-%d).md

end::
	git add .
	git commit -m "Update logs"
	git push

serve::
	hugo serve -D

build::
	hugo 

theme-update::
	git submodule update --remote --merge 
