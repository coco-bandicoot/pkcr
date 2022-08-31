import glob

filenames = glob.glob('data/pokemon/base_stats/*.asm')
allmondatafile = 'allmondata.txt'
mondata = {}

for filename in filenames:
	with open(filename, 'r', encoding='utf8') as file:
		lines = file.readlines()
	
	mondata[filename] = lines
	
with open(allmondatafile, 'w', encoding='utf8') as file:
	file.write(mondata)