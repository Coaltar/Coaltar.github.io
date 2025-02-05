BUILDDIR=build

PAGEDIR=pages
STATICDIR=static

PAGES=$(shell find $(PAGEDIR) -type f -name \*.md)
STATICS=$(shell find $(STATICDIR) -type f)
TEMPLATE=templates/default.html

PAGES_BUILT=$(patsubst $(PAGEDIR)/%.md,$(BUILDDIR)/%.html,$(PAGES))
STATICS_BUILT=$(patsubst static/%,$(BUILDDIR)/%,$(STATICS))
LUA_FILTER=rm-colgroup.lua

MD_TO_HTML=pandoc --from=markdown+yaml_metadata_block
MINIFIER=htmlmin --remove-comments --remove-all-empty-space
TOC_MAKER=npx markdown-toc --maxdepth 5 --no-stripHeadingTags --indent="  " --bullets="-" -i
MAPPER=npx markmap --no-open

DEVNAME=scoot-site

.PHONY: all clean dev stopdev

# all: $(BUILDDIR)/blog/index.html $(BUILDDIR)/mind-map/index.html $(PAGES_BUILT) $(STATICS_BUILT) 
all: $(BUILDDIR)/blog/index.html $(PAGES_BUILT) $(STATICS_BUILT) 

clean:
	rm -rf $(BUILDDIR)/*

$(BUILDDIR)/mind-map/index.html:
	@mkdir -p $(@D)
	./mapindex.sh | $(MD_TO_HTML) \
	--template=$(TEMPLATE) \
	-o $@
	$(MINIFIER) $@ $@

$(BUILDDIR)/blog/index.html: 
	@mkdir -p $(@D)
	./blogindex.sh | $(MD_TO_HTML) \
	--template=$(TEMPLATE) \
	-o $@
	$(MINIFIER) $@ $@

$(BUILDDIR)/%.html: $(PAGEDIR)/%.md $(TEMPLATE)
	@mkdir -p $(@D)
	$(TOC_MAKER) $<
	$(MD_TO_HTML) \
		--template=$(TEMPLATE) \
		--metadata="directory:$(subst pages/,,$<)" \
		-o $@ $<
	$(MINIFIER) $@ $@

$(BUILDDIR)/%: $(STATICDIR)/%
	@mkdir -p $(@D)
	cp -r $< $@

$(BUILDDIR)/%.css: $(STATICDIR)/%.css
	@mkdir -p $(@D)
	cp -r $< $@
	$(MINIFIER) $@ $@

dev: stopdev
	docker rm $(DEVNAME) | true
	docker run \
		-d \
		--network host \
		-v $(PWD)/$(BUILDDIR):/usr/local/apache2/htdocs \
		--name $(DEVNAME) \
		httpd:2

stopdev:
	docker kill $(DEVNAME) | true
