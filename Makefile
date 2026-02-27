all: intune-spec.pdf

intune-spec.pdf: intune-spec.html
	google-chrome --headless --disable-gpu --no-sandbox --print-to-pdf="$@" "file://$(CURDIR)/$<"

intune-spec.html: intune-spec.md
	pandoc --from=markdown_mmd -Vcss= -Vpagetitle="Intune for Linux Specification" --standalone --to=html intune-spec.md >$@

clean:
	rm intune-spec.pdf intune-spec.html >/dev/null 2>&1 || echo
