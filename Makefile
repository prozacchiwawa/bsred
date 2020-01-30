all: ./bsred.js

./bsred.js: src/*.ml ./editor.js
	npm run build
	browserify -o $@ ./editor.js
