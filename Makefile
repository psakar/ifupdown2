include /usr/share/dpkg/pkg-info.mk

PACKAGE=ifupdown2

SRCDIR=ifupdown2
BUILDDIR=$(SRCDIR)-$(DEB_VERSION)

GITVERSION:=$(shell git rev-parse HEAD)

ORIG_SRC_TAR=$(PACKAGE)_$(DEB_VERSION_UPSTREAM).orig.tar.gz
DSC=$(PACKAGE)_$(DEB_VERSION).dsc
DEB=$(PACKAGE)_$(DEB_VERSION)_all.deb

all: $(DEB)
	@echo $(DEB)

.PHONY: submodule
submodule:
	test -f "$(SRCDIR)/debian/changelog" || git submodule update --init

buildir: $(BUILDDIR)
$(BUILDDIR): submodule
	rm -rf $@ $@.tmp
	cp -a $(SRCDIR)/ $@.tmp/
	rm -rf $@.tmp/debian
	cp -a debian $@.tmp/
	mv $@.tmp $@

.PHONY: deb dsc
deb: $(DEB)
$(DEB): $(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -b -uc -us

$(ORIG_SRC_TAR): $(BUILDDIR)
	tar czf $(ORIG_SRC_TAR) --exclude="$(BUILDDIR)/debian" $(BUILDDIR)

dsc: $(DSC)
$(DSC): $(BUILDDIR) $(ORIG_SRC_TAR)
	cd $(BUILDDIR); dpkg-buildpackage -S -uc -us -d

sbuild: $(DSC)
	sbuild $(DSC)

.PHONY: upload
upload: UPLOAD_DIST ?= $(DEB_DISTRIBUTION)
upload: $(DEB)
	tar cf - $(DEB) | ssh -X repoman@repo.proxmox.com -- upload --product pve,pmg,pbs,pdm --dist $(UPLOAD_DIST)

.PHONY: distclean clean
distclean: clean
clean:
	rm -rf $(PACKAGE)-*/ *.deb *.dsc *.changes *.buildinfo *.build $(PACKAGE)*.tar.*

.PHONY: dinstall
dinstall: deb
	dpkg -i $(DEB)
