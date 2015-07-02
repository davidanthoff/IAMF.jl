using Lexicon
using IAMF

save(
	normpath(Pkg.dir("IAMF"), "doc", "reference.md"),
	IAMF,
	include_internal=false,
	md_subheader=:skip)
