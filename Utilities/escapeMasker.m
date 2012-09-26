function Path = escapeMasker(Path)

Path = regexprep(Path,'\\','\\\\');