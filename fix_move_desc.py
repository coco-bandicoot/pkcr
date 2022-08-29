import re

bkupfile = 'BKUP_move_descriptions.asm'
filename = 'data/moves/descriptions.asm'

with open(bkupfile, 'r', encoding='utf8') as file:
	lines = file.readlines()
with open(filename, 'w', encoding='utf8') as file:
	for line in lines:
		file.write(line)


with open(filename, 'r', encoding='utf8') as file:
	lines = file.readlines()

with open(filename, 'w', encoding='utf8') as file:
	for line in lines:
		replacenext = re.match('^\tnext (\".+@\"\n$)', line)
		addatsymbol = re.match('^(\tdb\s+\".+)\"\n$', line)
		print(line + ": " + str(addatsymbol))
		if ( replacenext != None ):
			content = replacenext.group(1)
			file.write('\tdb\t ' + content)
			continue
		if ( addatsymbol != None ):
			content = addatsymbol.group(1)
			file.write(content + "@\"\n")
			continue
		file.write(line)