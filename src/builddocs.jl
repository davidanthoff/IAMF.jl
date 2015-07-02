using Lexicon
using IAMF

save(
	normpath(Pkg.dir("IAMF"), "doc", "generated", "reference.md"),
	IAMF,
	include_internal=false,
	md_subheader=:skip)
