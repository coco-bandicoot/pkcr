import glob

filenames = glob.glob('data/pokemon/base_stats/*.asm')
allmondatafile = 'allmondata.txt'
mondata = []

for filename in filenames:
	with open(filename, 'r', encoding='utf8') as file:
		lines = file.readlines()
	
	# mondata[filename] = lines
	
	with open(allmondatafile, 'a', encoding='utf8') as file:
		file.write("'" + filename + "' : [\n")
		for line in lines:
			file.write("'\\t" + line[1:-1] + "\\n',\n")
		file.write("],\n\n")


