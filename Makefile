all: intune-spec.pdf

intune-spec.pdf: intune-spec.html
	# Requires wkhtmltopdf with patched qt
	wkhtmltopdf --footer-right "[page] / [topage]" --footer-left "Intune for Linux Specification" --footer-line --footer-font-name "Segoe UI" --footer-font-size 10 intune-spec.html intune-spec.pdf

intune-spec.html: intune-spec.md
	pandoc --from=markdown_mmd -Vcss= -Vpagetitle="Intune for Linux Specification" --standalone --to=html intune-spec.md >$@

clean:
	rm intune-spec.pdf intune-spec.html >/dev/null 2>&1 || echo
