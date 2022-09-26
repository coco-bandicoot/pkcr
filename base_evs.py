import glob

filenames = glob.glob('data/pokemon/dex_entries/*.asm')

for filename in filenames:
	print(filename[:-4])

	with open(filename, 'r', encoding='utf8') as file:
		lines = file.readlines()

	for line in lines:
		if '; height, weight' in line:
			print(line)