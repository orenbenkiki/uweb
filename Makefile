
all: man.html internals.html

man.html: uweb.rb
	./uweb.rb -h | asciidoctor -Basciidoc -a html -b html -o man.html -

internals.html: uweb.rb uweb.uw
	./uweb.rb uweb.uw > internals.html
